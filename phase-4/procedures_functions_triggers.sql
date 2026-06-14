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


-- тригер за проверка дека една песна не може да има релација (ремикс, препев, ...) со самата себе 
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
    -- site scopes dodeleni na ovoj user za torkata (action, resource_type)
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

    -- opredeli ownership + visibility za sekoj resource_type
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

    -- resursot ne postoi / nepoznat resource_type
    IF v_visibility IS NULL THEN
        RETURN FALSE;
    END IF;

    -- ANY scope dozvoluva se, nema potreba od dopolnitelni proverki (dokolku resursot postoi)
    IF 'ANY' = ANY (v_scopes) THEN
        RETURN TRUE;
    END IF;

    IF v_is_owner AND 'OWN' = ANY (v_scopes) THEN
        RETURN TRUE;
    END IF;

    IF v_visibility = 'PUBLIC' AND 'PUBLIC' = ANY (v_scopes) THEN
        RETURN TRUE;
    END IF;

    -- SHARED: resursot moze da e spodelen direktno so korisnikot 
    -- ILI so edna od roljite koja korisnikot gi poseduva, I samiot share dozvoluva p_action
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




-- тригер за проверка дали артистот и админот се дел од истата издавачка куќа при
-- објавување на песна/албум

CREATE OR REPLACE FUNCTION check_same_label()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.published_by_label_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM artist_labels al
            WHERE al.label_id = NEW.published_by_label_id
              AND al.artist_id = NEW.owner_artist_id
              AND al.active = TRUE
        ) THEN
            RAISE EXCEPTION 'Artist does not belong to this label';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS check_same_admin_artist_label ON songs;
DROP TRIGGER IF EXISTS check_same_admin_artist_label ON albums;

CREATE OR REPLACE TRIGGER check_same_admin_artist_label
    BEFORE INSERT OR UPDATE ON songs
    FOR EACH ROW
    EXECUTE FUNCTION check_same_label();


CREATE OR REPLACE TRIGGER check_same_admin_artist_label
    BEFORE INSERT OR UPDATE ON albums
    FOR EACH ROW
    EXECUTE FUNCTION check_same_label();



-- тригер за автоматско ажурирање на припадноста на артистот кон издавачка куќа при негово префрлање во нова издавачка куќа

CREATE OR REPLACE FUNCTION handle_new_artist_in_label()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE artist_labels
    SET end_date = NOW(),
        active = FALSE
    WHERE artist_id = NEW.artist_id
      AND active = TRUE;

    NEW.active := TRUE;
    NEW.start_date := NOW();

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS handle_new_artist_in_label ON artist_labels;

CREATE TRIGGER handle_new_artist_in_label
BEFORE INSERT ON artist_labels
FOR EACH ROW
EXECUTE FUNCTION handle_new_artist_in_label();


-- процедура за објавување на албум со песни

CREATE OR REPLACE PROCEDURE upload_album_with_songs(
    p_album_title VARCHAR,
    p_album_visibility VARCHAR,
    p_owner_artist_id BIGINT,
    p_published_by_artist_id BIGINT,
    p_published_by_label_id BIGINT,
    p_song_ids BIGINT[],
    INOUT p_album_id BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_song_ids IS NULL
       OR array_length(p_song_ids, 1) IS NULL THEN
        RAISE EXCEPTION 'Album must contain at least one song';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM albums
        WHERE title = p_album_title
    ) THEN
        RAISE EXCEPTION 'Album with that title already exists';
    END IF;

    INSERT INTO albums (
        title,
        visibility,
        owner_artist_id,
        published_by_artist_id,
        published_by_label_id
    )
    VALUES (
        p_album_title,
        p_album_visibility,
        p_owner_artist_id,
        p_published_by_artist_id,
        p_published_by_label_id
    )
    RETURNING id INTO p_album_id;

    INSERT INTO album_tracks (
        album_id,
        song_id,
        track_number
    )
    SELECT
        p_album_id,
        song_id,
        ordinality
    FROM unnest(p_song_ids)
         WITH ORDINALITY AS t(song_id, ordinality);
END;
$$;



-- процедура за ажурирање на сите материјализирани погледи

CREATE OR REPLACE PROCEDURE refresh_all_materialized_views()
LANGUAGE plpgsql
AS $$
DECLARE
    v_mv RECORD;
BEGIN
    FOR v_mv IN
        SELECT schemaname,
               matviewname
        FROM pg_matviews
        WHERE schemaname = 'public'
    LOOP
        RAISE NOTICE 'Refreshing %.%',
            v_mv.schemaname,
            v_mv.matviewname;

        EXECUTE format(
            'REFRESH MATERIALIZED VIEW %I.%I',
            v_mv.schemaname,
            v_mv.matviewname
        );
    END LOOP;
END;
$$;


-- функција за агрегирање на податоци од изминати song_streams партиции во song_stream_counts_archive 
-- и маркирање на тие месеци како затворени (податоците се користат во view #7)

-- помошни табели

CREATE TABLE IF NOT EXISTS song_stream_sealed_partitions (
    partition_month date        PRIMARY KEY, -- prviot den od zatvoreniot mesecot
    sealed_at       timestamptz NOT NULL DEFAULT now()
);

-- kumulativni brojaci po pesna za site do sega zatvoreni meseci
CREATE TABLE IF NOT EXISTS song_stream_counts_archive (
    song_id bigint PRIMARY KEY,
    streams bigint NOT NULL
);

CREATE OR REPLACE FUNCTION seal_closed_song_streams_months()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    current_month date := date_trunc('month', current_date)::date;
    r             record;
    yr            int;
    mo            int;
    part_month    date;
BEGIN
    FOR r IN -- iterirame niz sekoja particija
        SELECT c.relname
        FROM pg_inherits i
        JOIN pg_class c ON c.oid = i.inhrelid
        JOIN pg_class p ON p.oid = i.inhparent
        WHERE p.relname = 'song_streams'
          AND c.relname ~ '^song_streams_y\d{4}m\d{2}$'   -- isklucuva default particija
        ORDER BY c.relname                                -- pocnuva od najstarata
    LOOP
        yr         := substring(r.relname from 'y(\d{4})m')::int;
        mo         := substring(r.relname from 'm(\d{2})$')::int;
        part_month := make_date(yr, mo, 1);

        -- zatvarame (seal-nuvame) samo meseci koi se celosno pominati i ne se zatvoreni do sega
        CONTINUE WHEN part_month >= current_month;
        CONTINUE WHEN EXISTS (
            SELECT 1 FROM song_stream_sealed_partitions s
            WHERE s.partition_month = part_month
        );

        -- generira per-song brojaci za segasniot mesec i gi vnesuva so stream count arhivata
        -- koristenjeto na particiite tuka e eksplicitno (r e imeto na particioniranata tabela)
        EXECUTE format(
            'INSERT INTO song_stream_counts_archive AS a (song_id, streams) '
            'SELECT song_id, count(*) FROM %I GROUP BY song_id '
            'ON CONFLICT (song_id) DO UPDATE SET streams = a.streams + EXCLUDED.streams',
            r.relname
        );

        -- markiraj go kako sealed
        INSERT INTO song_stream_sealed_partitions (partition_month)
        VALUES (part_month);

        RAISE NOTICE 'sealed month %', to_char(part_month, 'YYYY-MM');
    END LOOP;
END;
$$;


-- функции за овозможување стриминг на песни

-- помошна функција за земање големина на песната во бајти.
-- backend-от ја користи за да го пресмета Content-Range header-от и да валидира опсези
CREATE OR REPLACE FUNCTION song_content_size(p_song_id bigint)
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
    SELECT octet_length(content)
    FROM song_contents
    WHERE song_id = p_song_id
    LIMIT 1;
$$;


-- функција која враќа сегмент бајти од песната - главната (core) функција корисна за самиот стриминг
--    p_start  - 0-indexed offset (како во HTTP Range), inclusive
--    p_length - колку бајти да се вратат од таа позиција

CREATE OR REPLACE FUNCTION song_content_chunk(
    p_song_id bigint,
    p_start   bigint,
    p_length  integer
)
RETURNS bytea
LANGUAGE sql
STABLE
AS $$
    SELECT substring(content FROM (p_start + 1)::int FOR p_length) -- substring() е 1-indexed па додаваме +1
    FROM song_contents
    WHERE song_id = p_song_id
    LIMIT 1;
$$;


-- функции за менаџирање на сесии (playback_session)

-- функција за започнување нова сесија (listened_ms = 0). враќа id-то на сесијата.

CREATE OR REPLACE FUNCTION start_playback_session(
    p_user_id bigint,
    p_song_id bigint
)
RETURNS bigint
LANGUAGE sql
AS $$
    INSERT INTO playback_sessions (user_id, song_id, started_at, listened_ms, last_position_ms)
    VALUES (p_user_id, p_song_id, now(), 0, 0)
    RETURNING id;
$$;

-- функција за update на сесијата согласно испратениот heartbeat од backend-от. 
-- доколку listened_ms надмине 30_000 поставениот тригер ќе направи запис во song_streams

CREATE OR REPLACE FUNCTION update_playback_progress(
    p_session_id      bigint,
    p_listened_ms     integer,
    p_last_position_ms integer
)
RETURNS void
LANGUAGE sql
AS $$
    UPDATE playback_sessions
    SET listened_ms      = p_listened_ms,
        last_position_ms = p_last_position_ms
    WHERE id = p_session_id;
$$;
