-- функции, тригери, процедури


-- тригер за додавање stream по додавање или ажурирање на сесија која траела подолго од 30 секунди

CREATE OR REPLACE FUNCTION trg_record_stream_from_session()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.listened_ms >= 30000
    AND NOT EXISTS (SELECT 1
                    FROM Song_Streams ss
                    WHERE ss.playback_session_id = NEW.id)
    THEN
        INSERT INTO Song_Streams (playback_session_id, song_id, streamed_at, user_id)
        VALUES (NEW.id, NEW.song_id, NEW.started_at, NEW.user_id);
    END IF;
    RETURN NEW;
END;
$$ language plpgsql;


DROP TRIGGER IF EXISTS record_stream_from_session on playback_sessions;

CREATE TRIGGER record_stream_from_session
    AFTER INSERT OR UPDATE OF listened_ms ON playback_sessions
    FOR EACH ROW
EXECUTE FUNCTION trg_record_stream_from_session();


-- тригер за проверка дека една песна не може да има релација (ремикс, препев, ...) со самата себе, 
-- и дека дека нема да има дупликати од истата релација

CREATE OR REPLACE FUNCTION trg_check_song_relationship()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.source_song_id = NEW.target_song_id THEN
        RAISE EXCEPTION 'A song cannot have a relationship with itself (song %)',
            NEW.source_song_id;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM Song_Relationships sr
        WHERE sr.source_song_id = NEW.source_song_id
          AND sr.target_song_id = NEW.target_song_id
          AND sr.relationship_type = NEW.relationship_type
          AND sr.id <> COALESCE(NEW.id, -1)
    ) THEN
        RAISE EXCEPTION 'Duplicate % relationship between songs % and %',
            NEW.relationship_type, NEW.source_song_id, NEW.target_song_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_song_relationship ON Song_Relationships;
CREATE TRIGGER check_song_relationship
    BEFORE INSERT OR UPDATE ON Song_Relationships
    FOR EACH ROW
EXECUTE FUNCTION trg_check_song_relationship();


-- функција за броење на бројот на слушања на одредена песна во изминат период

CREATE OR REPLACE FUNCTION song_stream_count(
    p_song_id BIGINT,
    p_window  INTERVAL DEFAULT INTERVAL '30 days'
) RETURNS BIGINT AS $$
SELECT COUNT(*)
FROM Song_Streams ss
WHERE ss.song_id = p_song_id
  AND ss.streamed_at >= CURRENT_TIMESTAMP - p_window;
$$ LANGUAGE sql STABLE;


-- функција за проверување дали даден корисник може да преземе одредена акција - главна авторизациска логика

CREATE OR REPLACE FUNCTION can_user_perform(
    p_user_id       BIGINT,
    p_action        VARCHAR,
    p_resource_type VARCHAR,
    p_resource_id   BIGINT
) RETURNS BOOLEAN AS $$
DECLARE
    v_scopes      TEXT[];
    v_is_owner    BOOLEAN := FALSE;
    v_visibility  TEXT;
    v_is_shared   BOOLEAN := FALSE;
BEGIN
    -- scopes granted to this user for (action, resource_type)
    SELECT ARRAY_AGG(DISTINCT p.scope)
    INTO v_scopes
    FROM User_Roles ur
    JOIN Role_Permissions rp ON rp.role_id = ur.role_id
    JOIN Permissions p ON p.id = rp.permission_id
    WHERE ur.user_id = p_user_id
      AND p.action = p_action
      AND p.resource_type = p_resource_type;

    IF v_scopes IS NULL THEN
        RETURN FALSE;
    END IF;

    -- resolve ownership + visibility per resource type
    IF p_resource_type = 'SONG' THEN
        SELECT s.visibility,
               EXISTS (SELECT 1 FROM Artists a
                       WHERE a.id = s.owner_artist_id
                         AND a.user_id = p_user_id)
        INTO v_visibility, v_is_owner
        FROM Songs s WHERE s.id = p_resource_id;

    ELSIF p_resource_type = 'ALBUM' THEN
        SELECT al.visibility,
               EXISTS (SELECT 1 FROM Artists a
                       WHERE a.id = al.owner_artist_id
                         AND a.user_id = p_user_id)
        INTO v_visibility, v_is_owner
        FROM Albums al WHERE al.id = p_resource_id;

    ELSIF p_resource_type = 'PLAYLIST' THEN
        SELECT pl.visibility,
               (pl.creator_user_id = p_user_id)
        INTO v_visibility, v_is_owner
        FROM Playlists pl WHERE pl.id = p_resource_id;
    END IF;

    -- resource does not exist (or unknown resource_type): nothing to authorize
    IF v_visibility IS NULL THEN
        RETURN FALSE;
    END IF;

    -- ANY scope short-circuits everything (resource is known to exist)
    IF 'ANY' = ANY (v_scopes) THEN
        RETURN TRUE;
    END IF;

    IF v_is_owner AND 'OWN' = ANY (v_scopes) THEN
        RETURN TRUE;
    END IF;

    IF v_visibility = 'PUBLIC' AND 'PUBLIC' = ANY (v_scopes) THEN
        RETURN TRUE;
    END IF;

    -- SHARED: resource shared directly with the user or with one of
    -- the roles the user holds, AND the share itself grants p_action
    IF 'SHARED' = ANY (v_scopes) THEN
        SELECT EXISTS (
            SELECT 1
            FROM Resource_Shares rs
            JOIN Permissions sp ON sp.id = rs.permission_id
            WHERE (
                    (p_resource_type = 'SONG'     AND rs.song_id     = p_resource_id) OR
                    (p_resource_type = 'ALBUM'    AND rs.album_id    = p_resource_id) OR
                    (p_resource_type = 'PLAYLIST' AND rs.playlist_id = p_resource_id)
                  )
              AND sp.action = p_action
              AND sp.resource_type = p_resource_type
              AND (
                    rs.user_id = p_user_id
                    OR rs.role_id IN (SELECT ur.role_id
                                      FROM User_Roles ur
                                      WHERE ur.user_id = p_user_id)
                  )
        ) INTO v_is_shared;

        IF v_is_shared THEN
            RETURN TRUE;
        END IF;
    END IF;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql STABLE;




-- Тригер за проверка дали артистот и админот се дел од истата издавачка куќа при
-- објавување на песна/албум

create or replace function check_same_label()
returns trigger
language plpgsql
as $$
begin
    if NEW.published_by_label_admin_id is not null then

        if not exists (
            select 1
            from label_admins la
            join artist_labels al on al.label_id = la.label_id
            where la.id = NEW.published_by_label_admin_id
              and al.artist_id = NEW.owner_artist_id
              and al.active = true
        ) then
            raise exception 'Admin and artist do not belong to the same label';
        end if;

    end if;

    return NEW;
end;
$$;


drop trigger if exists check_same_admin_artist_label on songs;
drop trigger if exists check_same_admin_artist_label on albums;

create or replace trigger check_same_admin_artist_label
    BEFORE insert or update on songs
    for each row
    execute function check_same_label();


create or replace trigger check_same_admin_artist_label
    BEFORE insert or update on albums
    for each row
    execute function check_same_label();




-- Тригер за автоматско ажурирање на припадноста на артистот кон издавачка куќа при негово префрлање во нова издавачка куќа

create or replace function handle_new_artist_in_label()
returns trigger
language plpgsql
as $$
begin
    update artist_labels
    set end_date = now(),
        active = false
    where artist_id = NEW.artist_id
      and active = true;

    NEW.active := true;
    NEW.start_date := now();

    return NEW;
end;
$$;

drop trigger if exists handle_new_artist_in_label on artist_labels;

create trigger handle_new_artist_in_label
before insert on artist_labels
for each row
execute function handle_new_artist_in_label();




-- Процедура за објавување на албум со песни


create or replace procedure upload_album_with_songs(
    p_album_title varchar,
    p_album_visibility varchar,
    p_owner_artist_id bigint,
    p_published_by_artist_id bigint,
    p_published_by_label_admin_id bigint,
    p_songs jsonb,
    inout p_album_id bigint default null,
    inout p_created_song_ids bigint[] default '{}'
)
language plpgsql
as $$
declare
    v_song jsonb;
    v_song_id bigint;
    v_track_number int := 1;
begin
    -- procedure-specific validation
    if jsonb_typeof(p_songs) <> 'array' then
        raise exception 'p_songs must be a JSON array';
    end if;

    if jsonb_array_length(p_songs) = 0 then
        raise exception 'Album must contain at least one song';
    end if;

    -- insert album
    -- your album trigger/check constraints will validate publisher rules
    insert into albums (
        title,
        visibility,
        owner_artist_id,
        published_by_artist_id,
        published_by_label_admin_id
    )
    values (
        p_album_title,
        p_album_visibility,
        p_owner_artist_id,
        p_published_by_artist_id,
        p_published_by_label_admin_id
    )
    returning id into p_album_id;

    -- insert songs and connect them to album_tracks
    for v_song in
        select value
        from jsonb_array_elements(p_songs)
    loop
        if coalesce(v_song ->> 'title', '') = '' then
            raise exception 'Every song must have a title';
        end if;

        insert into songs (
            title,
            visibility,
            owner_artist_id,
            published_by_artist_id,
            published_by_label_admin_id,
            genre
        )
        values (
            v_song ->> 'title',
            p_album_visibility,
            p_owner_artist_id,
            p_published_by_artist_id,
            p_published_by_label_admin_id,
            v_song ->> 'genre'
        )
        returning id into v_song_id;

        insert into album_tracks (
            album_id,
            song_id,
            track_number
        )
        values (
            p_album_id,
            v_song_id,
            v_track_number
        );

        p_created_song_ids := array_append(p_created_song_ids, v_song_id);
        v_track_number := v_track_number + 1;
    end loop;
end;
$$;




-- Процедура за ажурирање на сите материјализирани погледи

create or replace procedure refresh_all_materialized_views()
language plpgsql
as $$
declare
    v_mv record;
begin
    for v_mv in
        select schemaname,
               matviewname
        from pg_matviews
        where schemaname = 'public'
    loop
        raise notice 'Refreshing %.%',
            v_mv.schemaname,
            v_mv.matviewname;

        execute format(
            'refresh materialized view %I.%I',
            v_mv.schemaname,
            v_mv.matviewname
        );
    end loop;
end;
$$;


