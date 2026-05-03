drop view user_follow_info;
drop view user_activity_last_30_days;
drop view song_average_grade;

-- view #1 - for each user get followers and following
create view user_follow_info as
(
    with user_followers as (select followed_user_id as user_id, count(followed_user_id) as followers
                            from follows
                            group by followed_user_id),
         user_follows as (select follower_user_id as user_id, count(followed_user_id) as following
                          from follows
                          group by follower_user_id)
    select user_id, username, followers, following
    from user_follows
             natural join user_followers
             join users u on u.id = user_id
    order by followers desc
);

-- view #2 - most active users - users with the most streams in the last 30 days
create view user_activity_last_30_days as
(
    with streams_per_user as (select ss.user_id, count(ss.song_id) as stream_count
                              from song_streams ss
                              where ss.streamed_at between current_date - 30 and now()
                              group by ss.user_id)
    select u.username, spu.*
    from users u
             join streams_per_user spu on u.id = spu.user_id
    order by stream_count desc
);

-- view #3 - average review grade and number of reviews per song
create view song_average_grade as
(
    with avg_grade as (select song_id,
                              avg(r.grade)   as avg_grade,
                              count(r.grade) as num_reviews
                       from reviews r
                       group by r.song_id)
    select s.id       as song_id,
           s.title    as song_title,
           u.username as released_by,
           u.id       as user_id,
           ag.avg_grade,
           ag.num_reviews
    from songs s
             join avg_grade ag on ag.song_id = s.id
             join users u on u.id = s.owner_artist_id
    order by avg_grade desc, num_reviews desc
);


-- view #4 - most popular artists in the last  30 days

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



