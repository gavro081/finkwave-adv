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
    ORDER BY followers DESC
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
    ORDER BY stream_count DESC
);

-- view #3 - average review grade and number of review per song

CREATE OR REPLACE VIEW song_average_grade AS
(
    WITH avg_grade AS (SELECT song_id,
                              AVG(r.grade)   AS avg_grade,
                              COUNT(r.grade) AS num_reVIEWs
                       FROM reVIEWs r
                       GROUP BY r.song_id)
    SELECT s.id       AS song_id,
           s.title    AS song_title,
           u.username AS released_by,
           u.id       AS user_id,
           ag.avg_grade,
           ag.num_reVIEWs
    FROM songs s
             JOIN avg_grade ag ON ag.song_id = s.id
             JOIN users u ON u.id = s.owner_artist_id
    ORDER BY avg_grade DESC, num_reviews DESC
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
FROM artist_listens
ORDER BY total_listens DESC;


-- view #5 - most popular songs in the last 30 days

CREATE OR REPLACE VIEW most_popular_songs_last_30_days AS
WITH stream_counts AS (
    SELECT song_id, COUNT(*) AS total_streams
    FROM song_streams
    WHERE streamed_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY song_id
)
SELECT
    s.id AS song_id,
    s.title AS song_title,
    a.display_name AS artist_display_name,
    s.visibility AS song_visibility,
    u.username AS label_admin_username,
    l.name AS label_name,
    sc.total_streams
FROM stream_counts sc
JOIN songs s ON s.id = sc.song_id
JOIN artists a ON s.owner_artist_id = a.id
LEFT JOIN label_admins la ON s.published_by_label_admin_id = la.id
LEFT JOIN labels l ON l.id = la.label_id
LEFT JOIN users u ON u.id = la.user_id
ORDER BY sc.total_streams DESC;



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
LEFT JOIN songs s ON s.owner_artist_id = a.id
LEFT JOIN follows f ON f.followed_user_id = a.user_id
GROUP BY l.name, a.id, a.display_name
ORDER BY l.name, a.display_name;


