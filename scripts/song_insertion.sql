\set ON_ERROR_STOP on

BEGIN;

WITH new_song AS (
    INSERT INTO songs (title, visibility, owner_artist_id, published_by_artist_id, genre)
    VALUES ('Niz Mojot Zhivot', 'PUBLIC', 1, 1, 'rap')
    RETURNING id
)

INSERT INTO song_contents (song_id, content)
SELECT id,
       pg_read_binary_file(
            -- absolute path to song file
           '/Users/Filip/Desktop/dev/faks-projects/finkwave-advanced/streaming-demo/assets/song.mp3'
       )
FROM new_song;

COMMIT;

-- check
SELECT s.id   AS song_id,
       s.title,
       octet_length(sc.content) AS bytes
FROM songs s
JOIN song_contents sc ON sc.song_id = s.id
WHERE s.title = 'Niz Mojot Zhivot'
ORDER BY s.id DESC
LIMIT 1;
