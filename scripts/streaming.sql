-- 1. големина на песната во бајти.
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


-- 2. враќа сегмент бајти од песната
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


-- 3. менаџирање на сесии (playback_session)

-- 3a. почни нова сесија (listened_ms = 0). враќа id-то на сесијата.
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

-- 3b. update на сесијата согласно испратениот heartbeat од backend-от. 
-- доколку listened_ms надмине 30_000 поставениот тригер ќе направи запис во song_stream
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
