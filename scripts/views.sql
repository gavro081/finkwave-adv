DROP VIEW user_follow_info;
DROP VIEW user_activity_last_30_days;
DROP VIEW song_average_grade;

-- view #1 - for each user get followers and following
create or replace view user_follow_info as
(
    with user_followers as (select followed_user_id as user_id, count(followed_user_id) as followers
                        from follows
                        group by followed_user_id),
     user_follows as (select follower_user_id as user_id, count(followed_user_id) as following
                      from follows
                      group by follower_user_id)
    select uf1.user_id,
        username,
        coalesce(followers, 0) as followers,
        coalesce(following, 0) as following
    from user_follows uf1
            left join user_followers uf2 on uf1.user_id = uf2.user_id
            left join users u on u.id = uf1.user_id
    order by followers desc;
)

-- view #2 - most active users - users WITH the most streams in the last 30 days
CREATE VIEW user_activity_last_30_days AS
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

-- view #3 - average reVIEW grade and number of reVIEWs per song
CREATE VIEW song_average_grade AS
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
    ORDER BY avg_grade DESC, num_reVIEWs DESC
);


-- view #4 - most popular artists in the last 30 days

CREATE OR REPLACE VIEW most_popular_artists_last_30_days AS
WITH streams_count AS (
    SELECT ss.song_id, COUNT(*) AS cnt
    FROM song_streams ss
    WHERE ss.streamed_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY ss.song_id
)
SELECT
    a.id AS artist_id,
    a.display_name AS artist_display_name,
    COALESCE(SUM(sc.cnt), 0) AS total_listens
FROM artists a
LEFT JOIN songs s ON s.owner_artist_id = a.id
LEFT JOIN streams_count sc ON sc.song_id = s.id
GROUP BY a.id
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
WITH artist_followers AS (
    SELECT a.id AS artist_id,
           COUNT(f.followed_user_id) AS followers
    FROM artists a
    LEFT JOIN follows f ON f.followed_user_id = a.id
    GROUP BY a.id
),
artist_songs AS (
    SELECT a.id AS artist_id,
           COUNT(s.id) AS song_count
    FROM artists a
    LEFT JOIN songs s ON s.owner_artist_id = a.id
    GROUP BY a.id
)
SELECT
    l.name AS label_name,
    a.display_name AS artist_display_name,
    asng.song_count AS songs,
    af.followers AS followers
FROM artist_labels al
JOIN artists a ON al.artist_id = a.id
JOIN artist_songs asng ON asng.artist_id = a.id
JOIN artist_followers af ON af.artist_id = a.id
JOIN labels l ON al.label_id = l.id;



