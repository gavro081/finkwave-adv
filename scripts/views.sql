-- view #1 - for each user get followers and following

CREATE OR REPLACE VIEW user_follow_info AS
(
    WITH user_followers AS (SELECT followed_user_id AS user_id, count(followed_user_id) AS followers
                        FROM follows
                        GROUP BY followed_user_id),
     user_follows AS (SELECT follower_user_id AS user_id, count(followed_user_id) AS following
                      FROM follows
                      GROUP BY follower_user_id)
    SELECT uf1.user_id,
        username,
        coalesce(followers, 0) AS followers,
        coalesce(following, 0) AS following
    FROM user_follows uf1
            LEFT JOIN user_followers uf2 ON uf1.user_id = uf2.user_id
            LEFT JOIN users u ON u.id = uf1.user_id
);

-- view #2 - most active users - users with the most streams in the last 30 days

CREATE OR REPLACE VIEW user_activity_last_30_days AS
(
    WITH streams_per_user AS (SELECT ss.user_id, COUNT(ss.song_id) AS stream_count
                              FROM song_streams ss
                              WHERE ss.streamed_at BETWEEN current_date - 30 and now()
                              GROUP BY ss.user_id)
    SELECT u.username, spu.*
    FROM users u
             JOIN streams_per_user spu ON u.id = spu.user_id
);

-- view #3 - average review grade and number of review per song

CREATE OR REPLACE VIEW song_average_grade AS
(
    WITH avg_grade AS (SELECT song_id,
                              AVG(r.grade)   AS avg_grade,
                              COUNT(r.grade) AS num_reviews
                       FROM reVIEWs r
                       GROUP BY r.song_id)
    SELECT s.id       AS song_id,
           s.title    AS song_title,
           u.username AS released_by,
           u.id       AS user_id,
           ag.avg_grade,
           ag.num_reviews
    FROM songs s
             JOIN avg_grade ag ON ag.song_id = s.id
             JOIN users u ON u.id = s.owner_artist_id
    WHERE s.deleted_at IS NULL
);


-- view #4 - streams per artist in the last 30 days

CREATE OR REPLACE VIEW artist_popularity_last_30_days AS
WITH streams_count AS (
    SELECT ss.song_id, COUNT(*) AS cnt
    FROM song_streams ss
    WHERE ss.streamed_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY ss.song_id
),
artist_listens AS (
    SELECT
        a.id AS artist_id,
        a.display_name AS artist_display_name,
        COALESCE(SUM(sc.cnt), 0) AS total_listens
    FROM artists a
    LEFT JOIN songs s ON s.owner_artist_id = a.id
    LEFT JOIN streams_count sc ON sc.song_id = s.id
    GROUP BY a.id, a.display_name
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_listens DESC) AS rank,
    artist_id,
    artist_display_name,
    total_listens
FROM artist_listens;


-- view #5 - most popular songs in the last 30 days

CREATE OR REPLACE VIEW most_popular_songs_last_30_days AS
WITH stream_counts AS (
    SELECT
        song_id,
        COUNT(*) AS total_streams
    FROM song_streams
    WHERE streamed_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY song_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY sc.total_streams DESC) AS rank,
    s.id AS song_id,
    s.title AS song_title,
    a.display_name AS artist_display_name,
    s.visibility AS song_visibility,
    l.name AS label_name,
    sc.total_streams
FROM stream_counts sc
JOIN songs s ON s.id = sc.song_id
JOIN artists a ON s.owner_artist_id = a.id
LEFT JOIN labels l ON l.id = s.published_by_label_admin_id
WHERE s.deleted_at IS NULL;


-- view #6 - label's artists information

CREATE OR REPLACE VIEW label_artists_info AS
SELECT
    l.name AS label_name,
    a.display_name AS artist_display_name,
    COUNT(DISTINCT s.id) AS songs,
    COUNT(DISTINCT f.follower_user_id) AS followers
FROM labels l
JOIN artist_labels al ON al.label_id = l.id
JOIN artists a ON a.id = al.artist_id
LEFT JOIN songs s ON s.owner_artist_id = a.id AND s.deleted_at IS NULL
LEFT JOIN follows f ON f.followed_user_id = a.user_id
GROUP BY l.name, a.id, a.display_name
ORDER BY l.name;



-- view #7 - song details

-- иницијална верзија, нема да работи со новите партиционирани табели, но секако ќе биде рефакторирана понатаму
CREATE OR REPLACE VIEW songs_details AS
WITH stream_counts AS (
    SELECT
        song_id,
        COUNT(*) AS streams
    FROM song_streams
    GROUP BY song_id
),
playlist_counts AS (
    SELECT
        song_id,
        COUNT(*) AS saved_in_playlists
    FROM playlist_tracks
    GROUP BY song_id
)
SELECT
    s.title AS title,
    a.display_name AS artist_name,
    COALESCE(l.name, 'SOLO') AS label_name,
    COALESCE(sc.streams, 0) AS streams,
    COALESCE(alb.title, 'SINGLE') AS album_title,
    COALESCE(pc.saved_in_playlists, 0) AS saved_in_playlists,
    sag.num_reviews,
    sag.avg_grade
FROM songs s
LEFT JOIN artists a ON a.id = s.owner_artist_id
LEFT JOIN artist_labels al ON al.artist_id = a.id
LEFT JOIN labels l ON l.id = al.label_id
LEFT JOIN album_tracks at ON at.song_id = s.id
LEFT JOIN albums alb ON alb.id = at.album_id
LEFT JOIN stream_counts sc ON sc.song_id = s.id
LEFT JOIN playlist_counts pc ON pc.song_id = s.id
LEFT JOIN song_average_grade_mv sag ON sag.song_id = s.id
WHERE s.deleted_at IS NULL;


-- view #8 - streams history

CREATE OR REPLACE VIEW streams_history AS
SELECT
    u.id AS user_id,
    u.username,
    s.id AS song_id,
    s.title,
    ss.streamed_at,
    ps.listened_ms
FROM users u
JOIN song_streams ss ON ss.user_id = u.id
JOIN songs s ON s.id = ss.song_id
JOIN playback_sessions ps ON ps.id = ss.playback_session_id;



-- MATERIALIZED VIEWS FOR OPTIMIZATION

DROP VIEW artist_popularity_last_30_days;
DROP VIEW most_popular_songs_last_30_days;
DROP VIEW songs_details;
DROP VIEW song_average_grade_mv;

-- view #3

DROP MATERIALIZED VIEW IF EXISTS song_average_grade_mv CASCADE; 

CREATE MATERIALIZED VIEW song_average_grade_mv AS
SELECT s.id       AS song_id,
       s.title    AS song_title,
       u.username AS released_by,
       u.id       AS user_id,
       ag.avg_grade,
       ag.num_reviews
FROM (SELECT song_id,
             AVG(grade)   AS avg_grade,
             COUNT(grade) AS num_reviews
      FROM reviews
      GROUP BY song_id) ag
JOIN songs s ON s.id = ag.song_id
JOIN users u ON u.id = s.owner_artist_id
WHERE s.deleted_at IS NULL;

-- view #4

CREATE MATERIALIZED VIEW artist_popularity_last_30_days_mv AS
WITH streams_count AS (
    SELECT ss.song_id, COUNT(*) AS cnt
    FROM song_streams ss
    WHERE ss.streamed_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY ss.song_id
),
artist_listens AS (
    SELECT
        a.id AS artist_id,
        a.display_name AS artist_display_name,
        COALESCE(SUM(sc.cnt), 0) AS total_listens
    FROM artists a
    LEFT JOIN songs s ON s.owner_artist_id = a.id
    LEFT JOIN streams_count sc ON sc.song_id = s.id
    GROUP BY a.id, a.display_name
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_listens DESC) AS rank,
    artist_id,
    artist_display_name,
    total_listens
FROM artist_listens;



-- view #5

CREATE MATERIALIZED VIEW most_popular_songs_last_30_days_mv AS
WITH stream_counts AS (
    SELECT
        song_id,
        COUNT(*) AS total_streams
    FROM song_streams
    WHERE streamed_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY song_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY sc.total_streams DESC) AS rank,
    s.id AS song_id,
    s.title AS song_title,
    a.display_name AS artist_display_name,
    s.visibility AS song_visibility,
    l.name AS label_name,
    sc.total_streams
FROM stream_counts sc
JOIN songs s ON s.id = sc.song_id
JOIN artists a ON s.owner_artist_id = a.id
LEFT JOIN labels l ON l.id = s.published_by_label_id;


-- view #7

DROP MATERIALIZED VIEW IF EXISTS song_stream_counts_mv CASCADE;

CREATE MATERIALIZED VIEW song_stream_counts_mv AS
WITH live AS (
    -- where clause allows planner to only query the necessary partitions
    SELECT ss.song_id, count(*) AS streams
    FROM song_streams ss
    WHERE ss.streamed_at >= COALESCE(
              (SELECT max(partition_month) + interval '1 month'
               FROM song_stream_sealed_partitions),
              timestamp '-infinity'
          )
    GROUP BY ss.song_id
)
SELECT song_id, SUM(streams) AS streams
FROM (
    SELECT song_id, streams FROM song_stream_counts_archive -- baseline from above
    UNION ALL
    SELECT song_id, streams FROM live -- open (unsealed) month(s)
) t
GROUP BY song_id;

CREATE MATERIALIZED VIEW song_playlist_counts_mv AS
SELECT
    song_id,
    COUNT(*) AS saved_in_playlists
FROM playlist_tracks
GROUP BY song_id;


-- songs_details останува обичен view но сега прави join-ови со новите материјализирани погледи
CREATE OR REPLACE VIEW songs_details AS
SELECT
    s.title AS title,
    a.display_name AS artist_name,
    COALESCE(l.name, 'SOLO') AS label_name,
    COALESCE(sc.streams, 0) AS streams,
    COALESCE(alb.title, 'SINGLE') AS album_title,
    COALESCE(pc.saved_in_playlists, 0) AS saved_in_playlists,
    sag.num_reviews,
    ROUND(sag.avg_grade, 2) AS avg_grade
FROM songs s
LEFT JOIN artists a ON a.id = s.owner_artist_id
LEFT JOIN artist_labels al ON al.artist_id = a.id
LEFT JOIN labels l ON l.id = al.label_id
LEFT JOIN album_tracks at ON at.song_id = s.id
LEFT JOIN albums alb ON alb.id = at.album_id
LEFT JOIN song_stream_counts_mv sc ON sc.song_id = s.id
LEFT JOIN song_playlist_counts_mv pc ON pc.song_id = s.id
LEFT JOIN song_average_grade_mv sag ON sag.song_id = s.id;