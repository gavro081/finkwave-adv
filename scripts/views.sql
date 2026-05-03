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
