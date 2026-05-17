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


