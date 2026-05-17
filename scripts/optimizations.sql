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




create index idx_song_streams_streamed_at_song_id
on song_streams(streamed_at, song_id);

drop index idx_song_streams_streamed_at_song_id;

explain analyse
select *
from artist_popularity_last_30_days where artist_display_name='Rush';


CREATE INDEX idx_songs_owner_artist_id
ON songs(owner_artist_id);

-- WITHOUT OPTIMIZATION


--  Subquery Scan on artist_popularity_last_30_days  (cost=258658.87..261658.85 rows=500 width=60) (actual time=5248.277..5288.441 rows=41 loops=1)
--    Filter: ((artist_popularity_last_30_days.artist_display_name)::text = 'Rush'::text)
--    Rows Removed by Filter: 99959
--    ->  WindowAgg  (cost=258658.87..260408.85 rows=100000 width=60) (actual time=5247.481..5281.467 rows=100000 loops=1)
--          ->  Sort  (cost=258658.85..258908.85 rows=100000 width=52) (actual time=5247.444..5253.777 rows=100000 loops=1)
--                Sort Key: artist_listens.total_listens DESC
--                Sort Method: quicksort  Memory: 7706kB
--                ->  Subquery Scan on artist_listens  (cost=249104.03..250354.03 rows=100000 width=52) (actual time=5163.853..5210.492 rows=100000 loops=1)
--                      ->  HashAggregate  (cost=249104.03..250354.03 rows=100000 width=52) (actual time=5163.847..5200.274 rows=100000 loops=1)
--                            Group Key: a.id
--                            Batches: 1  Memory Usage: 22545kB
--                            ->  Hash Left Join  (cost=173161.35..239347.87 rows=1951232 width=28) (actual time=3172.252..4602.821 rows=1953805 loops=1)
--                                  Hash Cond: (s.id = sc.song_id)
--                                  ->  Hash Right Join  (cost=3618.00..64682.53 rows=1951232 width=28) (actual time=123.141..1016.733 rows=1953805 loops=1)
--                                        Hash Cond: (s.owner_artist_id = a.id)
--                                        ->  Seq Scan on songs s  (cost=0.00..55942.32 rows=1951232 width=16) (actual time=70.738..304.609 rows=1951232 loops=1)
--                                        ->  Hash  (cost=2368.00..2368.00 rows=100000 width=20) (actual time=52.166..52.167 rows=100000 loops=1)
--                                              Buckets: 131072  Batches: 1  Memory Usage: 6157kB
--                                              ->  Seq Scan on artists a  (cost=0.00..2368.00 rows=100000 width=20) (actual time=21.265..34.097 rows=100000 loops=1)
--                                  ->  Hash  (cost=167349.12..167349.12 rows=175538 width=16) (actual time=3048.716..3048.831 rows=304092 loops=1)
--                                        Buckets: 524288 (originally 262144)  Batches: 1 (originally 1)  Memory Usage: 18351kB
--                                        ->  Subquery Scan on sc  (cost=163838.36..167349.12 rows=175538 width=16) (actual time=2861.695..2967.031 rows=304092 loops=1)
--                                              ->  Finalize HashAggregate  (cost=163838.36..165593.74 rows=175538 width=16) (actual time=2861.688..2940.091 rows=304092 loops=1)
--                                                    Group Key: ss.song_id
--                                                    Batches: 1  Memory Usage: 36881kB
--                                                    ->  Gather  (cost=88357.02..160327.60 rows=702152 width=16) (actual time=2650.692..2751.352 rows=304092 loops=1)
--                                                          Workers Planned: 4
--                                                          Workers Launched: 0
--                                                          ->  Partial HashAggregate  (cost=87357.02..89112.40 rows=175538 width=16) (actual time=2650.252..2729.313 rows=304092 loops=1)
--                                                                Group Key: ss.song_id
--                                                                Batches: 1  Memory Usage: 36881kB
--                                                                ->  Parallel Seq Scan on song_streams ss  (cost=0.00..86108.61 rows=249682 width=8) (actual time=0.039..2307.530 rows=996439 loops=1)
--                                                                      Filter: (streamed_at >= (CURRENT_TIMESTAMP - '30 days'::interval))
--                                                                      Rows Removed by Filter: 5779244
--  Planning Time: 0.601 ms
--  JIT:
--    Functions: 38
--  "  Options: Inlining false, Optimization false, Expressions true, Deforming true"
--  "  Timing: Generation 2.191 ms (Deform 0.875 ms), Inlining 0.000 ms, Optimization 0.746 ms, Emission 20.211 ms, Total 23.149 ms"
--  Execution Time: 5295.544 ms



-- AFTER INDEXES ONLY

-- WindowAgg  (cost=132657.36..134407.34 rows=100000 width=60) (actual time=2878.456..2912.811 rows=100000 loops=1)
--   ->  Sort  (cost=132657.34..132907.34 rows=100000 width=52) (actual time=2878.421..2884.685 rows=100000 loops=1)
--         Sort Key: artist_listens.total_listens DESC
--         Sort Method: quicksort  Memory: 7706kB
--         ->  Subquery Scan on artist_listens  (cost=123102.52..124352.52 rows=100000 width=52) (actual time=2795.069..2840.462 rows=100000 loops=1)
--               ->  HashAggregate  (cost=123102.52..124352.52 rows=100000 width=52) (actual time=2795.063..2830.225 rows=100000 loops=1)
--                     Group Key: a.id
--                     Batches: 1  Memory Usage: 22545kB
--                     ->  Hash Left Join  (cost=47159.84..113346.36 rows=1951232 width=28) (actual time=826.776..2239.576 rows=1953805 loops=1)
--                           Hash Cond: (s.id = sc.song_id)
--                           ->  Hash Right Join  (cost=3618.00..64682.53 rows=1951232 width=28) (actual time=118.783..1004.286 rows=1953805 loops=1)
--                                 Hash Cond: (s.owner_artist_id = a.id)
--                                 ->  Seq Scan on songs s  (cost=0.00..55942.32 rows=1951232 width=16) (actual time=69.772..303.956 rows=1951232 loops=1)
--                                 ->  Hash  (cost=2368.00..2368.00 rows=100000 width=20) (actual time=48.780..48.781 rows=100000 loops=1)
--                                       Buckets: 131072  Batches: 1  Memory Usage: 6157kB
--                                       ->  Seq Scan on artists a  (cost=0.00..2368.00 rows=100000 width=20) (actual time=17.634..30.840 rows=100000 loops=1)
--                           ->  Hash  (cost=41347.61..41347.61 rows=175538 width=16) (actual time=707.572..707.574 rows=304102 loops=1)
--                                 Buckets: 524288 (originally 262144)  Batches: 1 (originally 1)  Memory Usage: 18351kB
--                                 ->  Subquery Scan on sc  (cost=37836.85..41347.61 rows=175538 width=16) (actual time=533.395..631.097 rows=304102 loops=1)
--                                       ->  HashAggregate  (cost=37836.85..39592.23 rows=175538 width=16) (actual time=533.387..597.876 rows=304102 loops=1)
--                                             Group Key: ss.song_id
--                                             Batches: 1  Memory Usage: 36881kB
--                                             ->  Index Only Scan using idx_song_streams_streamed_at_song_id on song_streams ss  (cost=0.44..32842.98 rows=998774 width=8) (actual time=0.057..245.680 rows=996484 loops=1)
--                                                   Index Cond: (streamed_at >= (CURRENT_TIMESTAMP - '30 days'::interval))
--                                                   Heap Fetches: 0
-- Planning Time: 0.573 ms
-- JIT:
--   Functions: 32
-- "  Options: Inlining false, Optimization false, Expressions true, Deforming true"
-- "  Timing: Generation 2.147 ms (Deform 0.709 ms), Inlining 0.000 ms, Optimization 0.652 ms, Emission 16.640 ms, Total 19.439 ms"
-- Execution Time: 2923.180 ms










-- MATERIALIZE

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

drop index idx_artist_popularity_mv_display_name,idx_artist_popularity_mv_rank;
create index idx_artist_popularity_mv_display_name
on artist_popularity_last_30_days_mv(artist_display_name);

create index idx_artist_popularity_mv_rank
on artist_popularity_last_30_days_mv(rank);

explain analyse
select *
from artist_popularity_last_30_days_mv where artist_display_name='Rush';


-- WITH MATERIALIZED VIEW AND NO INDEXES

-- Seq Scan on artist_popularity_last_30_days_mv  (cost=0.00..2082.00 rows=2 width=31) (actual time=0.210..9.704 rows=41 loops=1)
--   Filter: ((artist_display_name)::text = 'Rush'::text)
--   Rows Removed by Filter: 99959
-- Planning Time: 0.094 ms
-- Execution Time: 9.731 ms



explain analyze
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




-- Inserts and updates without index

explain analyze
insert into song_streams (user_id, song_id, streamed_at, playback_session_id)
select
    1,
    1,
    current_timestamp,
    1;

-- Insert on song_streams  (cost=0.00..0.02 rows=0 width=0) (actual time=1973.419..1973.420 rows=0 loops=1)
--   ->  Result  (cost=0.00..0.02 rows=1 width=40) (actual time=0.014..0.015 rows=1 loops=1)
-- Planning Time: 0.053 ms
-- Trigger for constraint song_streams_playback_session_id_fkey: time=1211.087 calls=1
-- Trigger for constraint song_streams_song_id_fkey: time=625.582 calls=1
-- Execution Time: 3810.126 ms

explain analyze
update song_streams
set streamed_at = streamed_at + interval '1 second'
where id = (
    select id
    from song_streams
    limit 1
);


-- Update on song_streams  (cost=0.45..8.47 rows=0 width=0) (actual time=409.981..409.983 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.02 rows=1 width=8) (actual time=0.064..0.066 rows=1 loops=1)
--           ->  Seq Scan on song_streams song_streams_1  (cost=0.00..124221.83 rows=6775683 width=8) (actual time=0.063..0.064 rows=1 loops=1)
--   ->  Index Scan using song_streams_pkey on song_streams  (cost=0.43..8.45 rows=1 width=14) (actual time=70.181..70.183 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.179 ms
-- Execution Time: 984.624 ms


-- AFTER INDEX

explain analyse
insert into song_streams (user_id, song_id, streamed_at, playback_session_id)
select
    1,
    1,
    current_timestamp,
    2;

-- Insert on song_streams  (cost=0.00..0.02 rows=0 width=0) (actual time=0.496..0.496 rows=0 loops=1)
--   ->  Result  (cost=0.00..0.02 rows=1 width=40) (actual time=0.086..0.086 rows=1 loops=1)
-- Planning Time: 0.058 ms
-- Trigger for constraint song_streams_playback_session_id_fkey: time=0.239 calls=1
-- Trigger for constraint song_streams_song_id_fkey: time=0.177 calls=1
-- Execution Time: 0.941 ms

explain analyze
update song_streams
set streamed_at = streamed_at + interval '1 second'
where id = (
    select id
    from song_streams
    limit 1
);


-- Update on song_streams  (cost=0.45..8.47 rows=0 width=0) (actual time=271.515..271.517 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.02 rows=1 width=8) (actual time=0.057..0.059 rows=1 loops=1)
--           ->  Seq Scan on song_streams song_streams_1  (cost=0.00..124221.84 rows=6775684 width=8) (actual time=0.057..0.057 rows=1 loops=1)
--   ->  Index Scan using song_streams_pkey on song_streams  (cost=0.43..8.45 rows=1 width=14) (actual time=0.099..0.101 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.178 ms
-- Execution Time: 271.598 ms



-- view #5 - most popular songs in the last 30 days

create or replace view most_popular_songs_last_30_days as
with stream_counts as (
    select
        song_id,
        count(*) as total_streams
    from song_streams
    where streamed_at >= current_timestamp - interval '30 days'
    group by song_id
)
select
    row_number() over (order by sc.total_streams desc) as rank,
    s.id as song_id,
    s.title as song_title,
    a.display_name as artist_display_name,
    s.visibility as song_visibility,
    u.username as label_admin_username,
    l.name as label_name,
    sc.total_streams
from stream_counts sc
join songs s on s.id = sc.song_id
join artists a on s.owner_artist_id = a.id
left join label_admins la on s.published_by_label_admin_id = la.id
left join labels l on l.id = la.label_id
left join users u on u.id = la.user_id;



explain analyse
select * from most_popular_songs_last_30_days where rank=15;


-- With index on song_streams

-- Subquery Scan on most_popular_songs_last_30_days  (cost=96713.63..122558.33 rows=878 width=96) (actual time=1471.660..1677.911 rows=1 loops=1)
--   Filter: (most_popular_songs_last_30_days.rank = 17)
--   Rows Removed by Filter: 16
--   ->  WindowAgg  (cost=96713.63..120364.14 rows=175535 width=96) (actual time=1471.640..1677.902 rows=17 loops=1)
--         Run Condition: (row_number() OVER (?) <= 17)
--         ->  Gather Merge  (cost=96713.50..117731.12 rows=175535 width=88) (actual time=1471.591..1677.843 rows=18 loops=1)
--               Workers Planned: 4
--               Workers Launched: 4
--               ->  Sort  (cost=95713.44..95823.15 rows=43884 width=88) (actual time=1433.450..1433.565 rows=564 loops=5)
--                     Sort Key: sc.total_streams DESC
--                     Sort Method: quicksort  Memory: 9470kB
--                     Worker 0:  Sort Method: quicksort  Memory: 9145kB
--                     Worker 1:  Sort Method: quicksort  Memory: 2511kB
--                     Worker 2:  Sort Method: quicksort  Memory: 2431kB
--                     Worker 3:  Sort Method: quicksort  Memory: 9520kB
--                     ->  Parallel Hash Join  (cost=49328.85..92329.67 rows=43884 width=88) (actual time=1114.045..1407.397 rows=60789 loops=5)
--                           Hash Cond: (s.owner_artist_id = a.id)
--                           ->  Hash Left Join  (cost=46637.31..89522.94 rows=43884 width=84) (actual time=1076.395..1343.191 rows=60789 loops=5)
--                                 Hash Cond: (s.published_by_label_admin_id = la.id)
--                                 ->  Hash Join  (cost=43501.50..86090.08 rows=43884 width=48) (actual time=1071.308..1327.862 rows=60789 loops=5)
--                                       Hash Cond: (s.id = sc.song_id)
--                                       ->  Parallel Seq Scan on songs s  (cost=0.00..41308.08 rows=487808 width=40) (actual time=0.092..135.322 rows=390246 loops=5)
--                                       ->  Hash  (cost=41307.31..41307.31 rows=175535 width=16) (actual time=1069.687..1069.689 rows=303945 loops=5)
--                                             Buckets: 524288 (originally 262144)  Batches: 1 (originally 1)  Memory Usage: 18344kB
--                                             ->  Subquery Scan on sc  (cost=37796.61..41307.31 rows=175535 width=16) (actual time=837.380..966.924 rows=303945 loops=5)
--                                                   ->  HashAggregate  (cost=37796.61..39551.96 rows=175535 width=16) (actual time=837.372..937.795 rows=303945 loops=5)
--                                                         Group Key: song_streams.song_id
--                                                         Batches: 1  Memory Usage: 36881kB
--                                                         Worker 0:  Batches: 1  Memory Usage: 36881kB
--                                                         Worker 1:  Batches: 1  Memory Usage: 36881kB
--                                                         Worker 2:  Batches: 1  Memory Usage: 36881kB
--                                                         Worker 3:  Batches: 1  Memory Usage: 36881kB
--                                                         ->  Index Only Scan using idx_song_streams_streamed_at_song_id on song_streams  (cost=0.44..32809.02 rows=997519 width=8) (actual time=0.137..407.430 rows=995226 loops=5)
--                                                               Index Cond: (streamed_at >= (CURRENT_TIMESTAMP - '30 days'::interval))
--                                                               Heap Fetches: 95
--                                 ->  Hash  (cost=3131.12..3131.12 rows=375 width=48) (actual time=4.957..4.961 rows=375 loops=5)
--                                       Buckets: 1024  Batches: 1  Memory Usage: 38kB
--                                       ->  Nested Loop Left Join  (cost=13.86..3131.12 rows=375 width=48) (actual time=0.389..4.675 rows=375 loops=5)
--                                             ->  Hash Left Join  (cost=13.44..21.18 rows=375 width=39) (actual time=0.317..0.558 rows=375 loops=5)
--                                                   Hash Cond: (la.label_id = l.id)
--                                                   ->  Seq Scan on label_admins la  (cost=0.00..6.75 rows=375 width=24) (actual time=0.068..0.157 rows=375 loops=5)
--                                                   ->  Hash  (cost=8.75..8.75 rows=375 width=31) (actual time=0.214..0.215 rows=375 loops=5)
--                                                         Buckets: 1024  Batches: 1  Memory Usage: 33kB
--                                                         ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=31) (actual time=0.051..0.109 rows=375 loops=5)
--                                             ->  Index Scan using users_pkey on users u  (cost=0.42..8.29 rows=1 width=25) (actual time=0.010..0.010 rows=1 loops=1875)
--                                                   Index Cond: (id = la.user_id)
--                           ->  Parallel Hash  (cost=1956.24..1956.24 rows=58824 width=20) (actual time=37.138..37.139 rows=20000 loops=5)
--                                 Buckets: 131072  Batches: 1  Memory Usage: 6528kB
--                                 ->  Parallel Seq Scan on artists a  (cost=0.00..1956.24 rows=58824 width=20) (actual time=27.866..30.351 rows=20000 loops=5)
-- Planning Time: 1.492 ms
-- JIT:
--   Functions: 235
-- "  Options: Inlining false, Optimization false, Expressions true, Deforming true"
-- "  Timing: Generation 14.075 ms (Deform 6.062 ms), Inlining 0.000 ms, Optimization 5.950 ms, Emission 133.686 ms, Total 153.711 ms"
-- Execution Time: 1682.017 ms







create materialized view most_popular_songs_last_30_days_mv as
with stream_counts as (
    select
        song_id,
        count(*) as total_streams
    from song_streams
    where streamed_at >= current_timestamp - interval '30 days'
    group by song_id
)
select
    row_number() over (order by sc.total_streams desc) as rank,
    s.id as song_id,
    s.title as song_title,
    a.display_name as artist_display_name,
    s.visibility as song_visibility,
    u.username as label_admin_username,
    l.name as label_name,
    sc.total_streams
from stream_counts sc
join songs s on s.id = sc.song_id
join artists a on s.owner_artist_id = a.id
left join label_admins la on s.published_by_label_admin_id = la.id
left join labels l on l.id = la.label_id
left join users u on u.id = la.user_id;


explain analyse
select * from most_popular_songs_last_30_days_mv where rank=17;

-- WITH MATERIALIZED VIEW

-- Gather  (cost=1000.00..6167.16 rows=1 width=96) (actual time=0.381..671.251 rows=1 loops=1)
--   Workers Planned: 2
--   Workers Launched: 2
--   ->  Parallel Seq Scan on most_popular_songs_last_30_days_mv  (cost=0.00..5167.06 rows=1 width=96) (actual time=417.275..638.156 rows=0 loops=3)
--         Filter: (rank = 17)
--         Rows Removed by Filter: 101315
-- Planning Time: 0.218 ms
-- Execution Time: 671.277 ms












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
GROUP BY l.name, a.id, a.display_name;



explain analyze
select *
from label_artists_info where label_name='Piercing Abyss Records';

create index idx_songs_owner_artist_id
on songs(owner_artist_id);
create index idx_artist_labels_label_id_artist_id
on artist_labels(label_id, artist_id);

drop index idx_songs_owner_artist_id,idx_artist_labels_label_id_artist_id;

-- Without indexes

-- Subquery Scan on label_artists_info  (cost=48955.19..49185.03 rows=1561 width=51) (actual time=3166.576..3196.926 rows=81 loops=1)
--   ->  GroupAggregate  (cost=48955.19..49169.42 rows=1561 width=59) (actual time=3166.575..3196.914 rows=81 loops=1)
--         Group Key: a.id
--         ->  Gather Merge  (cost=48955.19..49142.10 rows=1561 width=59) (actual time=3166.542..3196.531 rows=1660 loops=1)
--               Workers Planned: 4
--               Workers Launched: 4
--               ->  Sort  (cost=47955.14..47956.11 rows=390 width=59) (actual time=2548.301..2548.327 rows=332 loops=5)
-- "                    Sort Key: a.id, s.id"
--                     Sort Method: quicksort  Memory: 68kB
--                     Worker 0:  Sort Method: quicksort  Memory: 35kB
--                     Worker 1:  Sort Method: quicksort  Memory: 39kB
--                     Worker 2:  Sort Method: quicksort  Memory: 44kB
--                     Worker 3:  Sort Method: quicksort  Memory: 60kB
--                     ->  Nested Loop Left Join  (cost=3303.17..47938.35 rows=390 width=59) (actual time=254.314..2547.203 rows=332 loops=5)
--                           ->  Hash Join  (cost=3302.88..47724.69 rows=390 width=59) (actual time=202.108..1249.756 rows=328 loops=5)
--                                 Hash Cond: (a.id = al.artist_id)
--                                 ->  Parallel Hash Right Join  (cost=2691.54..45280.17 rows=487808 width=36) (actual time=42.618..1060.686 rows=390761 loops=5)
--                                       Hash Cond: (s.owner_artist_id = a.id)
--                                       ->  Parallel Seq Scan on songs s  (cost=0.00..41308.08 rows=487808 width=16) (actual time=0.371..871.469 rows=390246 loops=5)
--                                       ->  Parallel Hash  (cost=1956.24..1956.24 rows=58824 width=28) (actual time=41.753..41.754 rows=20000 loops=5)
--                                             Buckets: 131072  Batches: 1  Memory Usage: 7328kB
--                                             ->  Parallel Seq Scan on artists a  (cost=0.00..1956.24 rows=58824 width=28) (actual time=3.800..28.812 rows=20000 loops=5)
--                                 ->  Hash  (cost=610.34..610.34 rows=80 width=31) (actual time=152.360..152.362 rows=81 loops=5)
--                                       Buckets: 1024  Batches: 1  Memory Usage: 14kB
--                                       ->  Hash Join  (cost=9.70..610.34 rows=80 width=31) (actual time=51.681..152.281 rows=81 loops=5)
--                                             Hash Cond: (al.label_id = l.id)
--                                             ->  Seq Scan on artist_labels al  (cost=0.00..521.00 rows=30000 width=16) (actual time=11.763..115.238 rows=30000 loops=5)
--                                             ->  Hash  (cost=9.69..9.69 rows=1 width=31) (actual time=33.047..33.048 rows=1 loops=5)
--                                                   Buckets: 1024  Batches: 1  Memory Usage: 9kB
--                                                   ->  Seq Scan on labels l  (cost=0.00..9.69 rows=1 width=31) (actual time=32.998..33.038 rows=1 loops=5)
--                                                         Filter: ((name)::text = 'Piercing Abyss Records'::text)
--                                                         Rows Removed by Filter: 374
--                           ->  Index Scan using idx_follows_followed_user_id on follows f  (cost=0.29..0.47 rows=8 width=16) (actual time=3.764..3.959 rows=1 loops=1638)
--                                 Index Cond: (followed_user_id = a.user_id)
-- Planning Time: 1776.191 ms
-- Execution Time: 3197.076 ms


-- WITH INDEXES

-- Subquery Scan on label_artists_info  (cost=571.17..618.00 rows=1561 width=51) (actual time=4.634..5.127 rows=81 loops=1)
--   ->  GroupAggregate  (cost=571.17..602.39 rows=1561 width=59) (actual time=4.633..5.116 rows=81 loops=1)
--         Group Key: a.id
--         ->  Sort  (cost=571.17..575.07 rows=1561 width=59) (actual time=4.614..4.708 rows=1660 loops=1)
-- "              Sort Key: a.id, s.id"
--               Sort Method: quicksort  Memory: 171kB
--               ->  Nested Loop Left Join  (cost=6.04..488.37 rows=1561 width=59) (actual time=0.125..3.388 rows=1660 loops=1)
--                     ->  Nested Loop Left Join  (cost=5.62..274.33 rows=80 width=51) (actual time=0.115..0.973 rows=83 loops=1)
--                           ->  Nested Loop  (cost=5.32..230.51 rows=80 width=51) (actual time=0.105..0.685 rows=81 loops=1)
--                                 ->  Nested Loop  (cost=4.91..175.24 rows=80 width=31) (actual time=0.092..0.265 rows=81 loops=1)
--                                       ->  Seq Scan on labels l  (cost=0.00..9.69 rows=1 width=31) (actual time=0.051..0.075 rows=1 loops=1)
--                                             Filter: ((name)::text = 'Piercing Abyss Records'::text)
--                                             Rows Removed by Filter: 374
--                                       ->  Bitmap Heap Scan on artist_labels al  (cost=4.91..164.75 rows=80 width=16) (actual time=0.038..0.174 rows=81 loops=1)
--                                             Recheck Cond: (l.id = label_id)
--                                             Heap Blocks: exact=72
--                                             ->  Bitmap Index Scan on idx_artist_labels_label_id_artist_id  (cost=0.00..4.89 rows=80 width=0) (actual time=0.019..0.019 rows=81 loops=1)
--                                                   Index Cond: (label_id = l.id)
--                                 ->  Index Scan using artists_pkey on artists a  (cost=0.42..0.69 rows=1 width=28) (actual time=0.005..0.005 rows=1 loops=81)
--                                       Index Cond: (id = al.artist_id)
--                           ->  Index Scan using idx_follows_followed_user_id on follows f  (cost=0.29..0.47 rows=8 width=16) (actual time=0.003..0.003 rows=1 loops=81)
--                                 Index Cond: (followed_user_id = a.user_id)
--                     ->  Index Scan using idx_songs_owner_artist_id on songs s  (cost=0.43..2.42 rows=26 width=16) (actual time=0.004..0.026 rows=20 loops=83)
--                           Index Cond: (owner_artist_id = a.id)
-- Planning Time: 1.229 ms
-- Execution Time: 5.213 ms


-- INSERTS AND UPDATES WITHOUT INDEXES

explain analyze
insert into artist_labels (artist_id, label_id, active, start_date)
select
    a.id,
    l.id,
    true,
    current_date
from artists a
cross join labels l
limit 1;


-- Insert on artist_labels  (cost=0.00..0.02 rows=0 width=0) (actual time=0.659..0.660 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.02 rows=1 width=33) (actual time=0.617..0.619 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.02 rows=1 width=21) (actual time=0.607..0.609 rows=1 loops=1)
--               ->  Nested Loop  (cost=0.00..564877.69 rows=37500000 width=21) (actual time=0.606..0.607 rows=1 loops=1)
--                     ->  Seq Scan on artists a  (cost=0.00..2368.00 rows=100000 width=8) (actual time=0.585..0.585 rows=1 loops=1)
--                     ->  Materialize  (cost=0.00..10.62 rows=375 width=8) (actual time=0.014..0.014 rows=1 loops=1)
--                           ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=8) (actual time=0.011..0.011 rows=1 loops=1)
-- Planning Time: 0.151 ms
-- Trigger for constraint artist_labels_artist_id_fkey: time=0.133 calls=1
-- Trigger for constraint artist_labels_label_id_fkey: time=0.080 calls=1
-- Execution Time: 0.914 ms



explain analyze
update artist_labels
set label_id = label_id
where id = (
    select id
    from artist_labels
    limit 1
);

-- Update on artist_labels  (cost=0.30..8.32 rows=0 width=0) (actual time=484.858..484.860 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.02 rows=1 width=8) (actual time=15.403..15.405 rows=1 loops=1)
--           ->  Seq Scan on artist_labels artist_labels_1  (cost=0.00..521.00 rows=30000 width=8) (actual time=15.402..15.403 rows=1 loops=1)
--   ->  Index Scan using artist_labels_pkey on artist_labels  (cost=0.29..8.30 rows=1 width=14) (actual time=484.755..484.757 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.271 ms
-- Execution Time: 712.000 ms





explain analyze
insert into songs (
    title,
    visibility,
    owner_artist_id,
    published_by_artist_id
)
select
    'Test song',
    'PUBLIC',
    a.id,
    a.id
from artists a
limit 1;


-- Insert on songs  (cost=0.00..0.04 rows=0 width=0) (actual time=582.569..582.571 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.04 rows=1 width=1202) (actual time=189.461..189.466 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.02 rows=1 width=80) (actual time=0.652..0.654 rows=1 loops=1)
--               ->  Seq Scan on artists a  (cost=0.00..2368.00 rows=100000 width=80) (actual time=0.651..0.652 rows=1 loops=1)
-- Planning Time: 52.941 ms
-- Trigger for constraint songs_owner_artist_id_fkey: time=0.370 calls=1
-- Trigger for constraint songs_published_by_artist_id_fkey: time=0.182 calls=1
-- Trigger for constraint songs_published_by_label_admin_id_fkey: time=0.013 calls=1
-- Execution Time: 583.185 ms

explain analyze
update songs
set owner_artist_id = owner_artist_id
where id = (
    select id
    from songs
    limit 1
);

-- Update on songs  (cost=0.46..8.47 rows=0 width=0) (actual time=540.365..540.367 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.03 rows=1 width=8) (actual time=0.033..0.034 rows=1 loops=1)
--           ->  Seq Scan on songs songs_1  (cost=0.00..55942.32 rows=1951232 width=8) (actual time=0.032..0.033 rows=1 loops=1)
--   ->  Index Scan using songs_pkey on songs  (cost=0.43..8.45 rows=1 width=14) (actual time=539.992..539.994 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.161 ms
-- Execution Time: 540.493 ms


-- INSERTS AND UPDATES WITH INDEXES

insert into artist_labels (artist_id, label_id, active, start_date)
select
    a.id,
    l.id,
    true,
    current_date
from artists a
cross join labels l
limit 1;

-- Insert on artist_labels  (cost=0.00..0.02 rows=0 width=0) (actual time=0.853..0.855 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.02 rows=1 width=33) (actual time=0.640..0.643 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.02 rows=1 width=21) (actual time=0.631..0.633 rows=1 loops=1)
--               ->  Nested Loop  (cost=0.00..564877.69 rows=37500000 width=21) (actual time=0.630..0.631 rows=1 loops=1)
--                     ->  Seq Scan on artists a  (cost=0.00..2368.00 rows=100000 width=8) (actual time=0.610..0.610 rows=1 loops=1)
--                     ->  Materialize  (cost=0.00..10.62 rows=375 width=8) (actual time=0.013..0.014 rows=1 loops=1)
--                           ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=8) (actual time=0.011..0.011 rows=1 loops=1)
-- Planning Time: 0.150 ms
-- Trigger for constraint artist_labels_artist_id_fkey: time=0.136 calls=1
-- Trigger for constraint artist_labels_label_id_fkey: time=0.081 calls=1
-- Execution Time: 1.113 ms


explain analyze
update artist_labels
set label_id = label_id
where id = (
    select id
    from artist_labels
    limit 1
);

-- Update on artist_labels  (cost=0.30..8.32 rows=0 width=0) (actual time=1731.646..1731.649 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.02 rows=1 width=8) (actual time=0.027..0.028 rows=1 loops=1)
--           ->  Seq Scan on artist_labels artist_labels_1  (cost=0.00..521.02 rows=30002 width=8) (actual time=0.026..0.026 rows=1 loops=1)
--   ->  Index Scan using artist_labels_pkey on artist_labels  (cost=0.29..8.30 rows=1 width=14) (actual time=0.050..0.054 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.149 ms
-- Execution Time: 1731.691 ms


explain analyze
insert into songs (
    title,
    visibility,
    owner_artist_id,
    published_by_artist_id
)
select
    'Test song',
    'PUBLIC',
    a.id,
    a.id
from artists a
limit 1;


-- Insert on songs  (cost=0.00..0.04 rows=0 width=0) (actual time=4.701..4.701 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.04 rows=1 width=1202) (actual time=4.324..4.326 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.02 rows=1 width=80) (actual time=4.294..4.295 rows=1 loops=1)
--               ->  Seq Scan on artists a  (cost=0.00..2368.00 rows=100000 width=80) (actual time=4.293..4.293 rows=1 loops=1)
-- Planning Time: 0.111 ms
-- Trigger for constraint songs_owner_artist_id_fkey: time=0.186 calls=1
-- Trigger for constraint songs_published_by_artist_id_fkey: time=0.081 calls=1
-- Trigger for constraint songs_published_by_label_admin_id_fkey: time=0.004 calls=1
-- Execution Time: 5.110 ms


explain analyze
update songs
set owner_artist_id = owner_artist_id
where id = (
    select id
    from songs
    limit 1
);


-- Update on songs  (cost=0.46..8.47 rows=0 width=0) (actual time=2490.120..2490.123 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.03 rows=1 width=8) (actual time=0.061..0.062 rows=1 loops=1)
--           ->  Seq Scan on songs songs_1  (cost=0.00..55942.33 rows=1951233 width=8) (actual time=0.059..0.060 rows=1 loops=1)
--   ->  Index Scan using songs_pkey on songs  (cost=0.43..8.45 rows=1 width=14) (actual time=108.993..108.996 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.174 ms
-- Execution Time: 2490.211 ms







-- view #7 Song details



create or replace view songs_details as
with stream_counts as (
    select
        song_id,
        count(*) as streams
    from song_streams
    group by song_id
),
playlist_counts as (
    select
        song_id,
        count(*) as saved_in_playlists
    from playlist_tracks
    group by song_id
)
select
    s.title as title,
    a.display_name as artist_name,
    coalesce(l.name, 'SOLO') as label_name,
    coalesce(sc.streams, 0) as streams,
    coalesce(alb.title, 'SINGLE') as album_title,
    coalesce(pc.saved_in_playlists, 0) as saved_in_playlists,
    sag.num_reviews,
    sag.avg_grade
from songs s
left join artists a on a.id = s.owner_artist_id
left join artist_labels al on al.artist_id = a.id
left join labels l on l.id = al.label_id
left join album_tracks at on at.song_id = s.id
left join albums alb on alb.id = at.album_id
left join stream_counts sc on sc.song_id = s.id
left join playlist_counts pc on pc.song_id = s.id
left join song_average_grade_mv sag on sag.song_id = s.id;


select * from users limit 1;

select * from songs_details where title='Harmony';





create index idx_songs_title
on songs(title);

create index idx_album_tracks_song_id
on album_tracks(song_id);

create index idx_artist_labels_artist_id
on artist_labels(artist_id);



-- WITHOUT INDEXES

-- Gather  (cost=230200.46..235882.48 rows=2211 width=121) (actual time=3427.813..93875.377 rows=1683 loops=1)
--   Workers Planned: 3
--   Workers Launched: 3
--   ->  Nested Loop Left Join  (cost=229200.46..234661.38 rows=713 width=121) (actual time=3393.680..41801.988 rows=421 loops=4)
--         ->  Merge Left Join  (cost=229200.03..229252.13 rows=713 width=85) (actual time=3393.619..3396.837 rows=421 loops=4)
--               Merge Cond: (s.id = pc.song_id)
--               ->  Sort  (cost=225567.13..225568.91 rows=713 width=77) (actual time=3342.494..3342.739 rows=421 loops=4)
--                     Sort Key: s.id
--                     Sort Method: quicksort  Memory: 48kB
--                     Worker 0:  Sort Method: quicksort  Memory: 44kB
--                     Worker 1:  Sort Method: quicksort  Memory: 44kB
--                     Worker 2:  Sort Method: quicksort  Memory: 72kB
--                     ->  Nested Loop Left Join  (cost=209283.95..225533.34 rows=713 width=77) (actual time=3254.123..3342.167 rows=421 loops=4)
--                           ->  Parallel Hash Right Join  (cost=209283.53..225211.18 rows=713 width=72) (actual time=3254.061..3337.679 rows=421 loops=4)
--                                 Hash Cond: (at.song_id = s.id)
--                                 ->  Parallel Seq Scan on album_tracks at  (cost=0.00..14292.12 rows=435812 width=16) (actual time=0.016..39.432 rows=337754 loops=4)
--                                 ->  Parallel Hash  (cost=209276.62..209276.62 rows=553 width=64) (actual time=3253.381..3253.392 rows=421 loops=4)
--                                       Buckets: 4096  Batches: 1  Memory Usage: 192kB
--                                       ->  Hash Left Join  (cost=164727.43..209276.62 rows=553 width=64) (actual time=3174.557..3252.826 rows=421 loops=4)
--                                             Hash Cond: (s.id = sc.song_id)
--                                             ->  Hash Left Join  (cost=909.90..45457.64 rows=553 width=56) (actual time=52.511..130.411 rows=421 loops=4)
--                                                   Hash Cond: (al.label_id = l.id)
--                                                   ->  Hash Left Join  (cost=896.46..45442.74 rows=553 width=41) (actual time=52.297..129.994 rows=421 loops=4)
--                                                         Hash Cond: (a.id = al.artist_id)
--                                                         ->  Nested Loop Left Join  (cost=0.42..44542.96 rows=553 width=41) (actual time=41.010..118.277 rows=421 loops=4)
--                                                               ->  Parallel Seq Scan on songs s  (cost=0.00..42527.60 rows=553 width=29) (actual time=40.894..112.485 rows=421 loops=4)
--                                                                     Filter: ((title)::text = 'Harmony'::text)
--                                                                     Rows Removed by Filter: 487388
--                                                               ->  Index Scan using artists_pkey on artists a  (cost=0.42..3.64 rows=1 width=20) (actual time=0.012..0.012 rows=1 loops=1683)
--                                                                     Index Cond: (id = s.owner_artist_id)
--                                                         ->  Hash  (cost=521.02..521.02 rows=30002 width=16) (actual time=11.075..11.076 rows=30003 loops=4)
--                                                               Buckets: 32768  Batches: 1  Memory Usage: 1663kB
--                                                               ->  Seq Scan on artist_labels al  (cost=0.00..521.02 rows=30002 width=16) (actual time=0.053..4.694 rows=30003 loops=4)
--                                                   ->  Hash  (cost=8.75..8.75 rows=375 width=31) (actual time=0.190..0.191 rows=375 loops=4)
--                                                         Buckets: 1024  Batches: 1  Memory Usage: 33kB
--                                                         ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=31) (actual time=0.030..0.089 rows=375 loops=4)
--                                             ->  Hash  (cost=161618.58..161618.58 rows=175916 width=16) (actual time=3120.501..3120.503 rows=635893 loops=4)
--                                                   Buckets: 1048576 (originally 262144)  Batches: 1 (originally 1)  Memory Usage: 38000kB
--                                                   ->  Subquery Scan on sc  (cost=158100.26..161618.58 rows=175916 width=16) (actual time=2662.167..2922.708 rows=635893 loops=4)
--                                                         ->  HashAggregate  (cost=158100.26..159859.42 rows=175916 width=16) (actual time=2662.160..2862.916 rows=635893 loops=4)
--                                                               Group Key: song_streams.song_id
--                                                               Batches: 1  Memory Usage: 65553kB
--                                                               Worker 0:  Batches: 1  Memory Usage: 65553kB
--                                                               Worker 1:  Batches: 1  Memory Usage: 65553kB
--                                                               Worker 2:  Batches: 1  Memory Usage: 65553kB
--                                                               ->  Seq Scan on song_streams  (cost=0.00..124221.84 rows=6775684 width=8) (actual time=0.040..834.432 rows=6775685 loops=4)
--                           ->  Index Scan using albums_pkey on albums alb  (cost=0.42..0.45 rows=1 width=21) (actual time=0.010..0.010 rows=1 loops=1683)
--                                 Index Cond: (id = at.album_id)
--               ->  Sort  (cost=3632.91..3657.15 rows=9698 width=16) (actual time=51.065..52.559 rows=10235 loops=4)
--                     Sort Key: pc.song_id
--                     Sort Method: quicksort  Memory: 706kB
--                     Worker 0:  Sort Method: quicksort  Memory: 706kB
--                     Worker 1:  Sort Method: quicksort  Memory: 706kB
--                     Worker 2:  Sort Method: quicksort  Memory: 706kB
--                     ->  Subquery Scan on pc  (cost=2796.77..2990.73 rows=9698 width=16) (actual time=45.054..47.748 rows=10288 loops=4)
--                           ->  HashAggregate  (cost=2796.77..2893.75 rows=9698 width=16) (actual time=45.048..46.739 rows=10288 loops=4)
--                                 Group Key: playlist_tracks.song_id
--                                 Batches: 1  Memory Usage: 1425kB
--                                 Worker 0:  Batches: 1  Memory Usage: 1425kB
--                                 Worker 1:  Batches: 1  Memory Usage: 1425kB
--                                 Worker 2:  Batches: 1  Memory Usage: 1425kB
--                                 ->  Seq Scan on playlist_tracks  (cost=0.00..2171.18 rows=125118 width=8) (actual time=0.038..14.065 rows=125118 loops=4)
--         ->  Index Scan using idx_sag_mv_song_id on song_average_grade_mv sag  (cost=0.43..7.58 rows=1 width=24) (actual time=91.275..91.276 rows=1 loops=1683)
--               Index Cond: (song_id = s.id)
-- Planning Time: 2.976 ms
-- JIT:
--   Functions: 272
-- "  Options: Inlining false, Optimization false, Expressions true, Deforming true"
-- "  Timing: Generation 16.724 ms (Deform 7.604 ms), Inlining 0.000 ms, Optimization 6.390 ms, Emission 157.809 ms, Total 180.923 ms"
-- Execution Time: 93882.201 ms


-- WITH INDEXES

-- Gather  (cost=188600.68..198746.59 rows=2211 width=121) (actual time=3136.649..3592.763 rows=1683 loops=1)
--   Workers Planned: 1
--   Workers Launched: 1
--   ->  Nested Loop Left Join  (cost=187600.68..197525.49 rows=1301 width=121) (actual time=3114.199..3121.952 rows=842 loops=2)
--         ->  Merge Left Join  (cost=187600.25..187655.31 rows=1301 width=85) (actual time=3114.146..3116.186 rows=842 loops=2)
--               Merge Cond: (s.id = pc.song_id)
--               ->  Sort  (cost=183967.34..183970.60 rows=1301 width=77) (actual time=3064.947..3065.100 rows=842 loops=2)
--                     Sort Key: s.id
--                     Sort Method: quicksort  Memory: 143kB
--                     Worker 0:  Sort Method: quicksort  Memory: 40kB
--                     ->  Hash Left Join  (cost=166553.22..183900.05 rows=1301 width=77) (actual time=3047.496..3064.384 rows=842 loops=2)
--                           Hash Cond: (s.id = sc.song_id)
--                           ->  Nested Loop Left Join  (cost=2735.67..20079.09 rows=1301 width=69) (actual time=64.333..80.679 rows=842 loops=2)
--                                 ->  Nested Loop Left Join  (cost=2735.25..19491.26 rows=1301 width=64) (actual time=64.294..76.539 rows=842 loops=2)
--                                       ->  Hash Left Join  (cost=2734.82..10204.79 rows=1301 width=56) (actual time=64.235..70.862 rows=842 loops=2)
--                                             Hash Cond: (al.label_id = l.id)
--                                             ->  Nested Loop Left Join  (cost=2721.39..10187.90 rows=1301 width=41) (actual time=64.055..70.410 rows=842 loops=2)
--                                                   ->  Parallel Hash Left Join  (cost=2721.10..9762.21 rows=1301 width=41) (actual time=64.004..67.464 rows=842 loops=2)
--                                                         Hash Cond: (s.owner_artist_id = a.id)
--                                                         ->  Parallel Bitmap Heap Scan on songs s  (cost=29.56..7067.26 rows=1301 width=29) (actual time=0.629..2.990 rows=842 loops=2)
--                                                               Recheck Cond: ((title)::text = 'Harmony'::text)
--                                                               Heap Blocks: exact=1395
--                                                               ->  Bitmap Index Scan on idx_songs_title  (cost=0.00..29.01 rows=2211 width=0) (actual time=0.323..0.324 rows=1683 loops=1)
--                                                                     Index Cond: ((title)::text = 'Harmony'::text)
--                                                         ->  Parallel Hash  (cost=1956.24..1956.24 rows=58824 width=20) (actual time=62.392..62.393 rows=50000 loops=2)
--                                                               Buckets: 131072  Batches: 1  Memory Usage: 6496kB
--                                                               ->  Parallel Seq Scan on artists a  (cost=0.00..1956.24 rows=58824 width=20) (actual time=38.029..44.369 rows=50000 loops=2)
--                                                   ->  Index Scan using idx_artist_labels_artist_id on artist_labels al  (cost=0.29..0.32 rows=1 width=16) (actual time=0.003..0.003 rows=0 loops=1683)
--                                                         Index Cond: (artist_id = a.id)
--                                             ->  Hash  (cost=8.75..8.75 rows=375 width=31) (actual time=0.155..0.155 rows=375 loops=2)
--                                                   Buckets: 1024  Batches: 1  Memory Usage: 33kB
--                                                   ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=31) (actual time=0.031..0.079 rows=375 loops=2)
--                                       ->  Index Scan using idx_album_tracks_song_id on album_tracks at  (cost=0.43..7.13 rows=1 width=16) (actual time=0.006..0.006 rows=1 loops=1683)
--                                             Index Cond: (song_id = s.id)
--                                 ->  Index Scan using albums_pkey on albums alb  (cost=0.42..0.45 rows=1 width=21) (actual time=0.004..0.004 rows=1 loops=1683)
--                                       Index Cond: (id = at.album_id)
--                           ->  Hash  (cost=161618.60..161618.60 rows=175916 width=16) (actual time=2982.071..2982.073 rows=635893 loops=2)
--                                 Buckets: 1048576 (originally 262144)  Batches: 1 (originally 1)  Memory Usage: 38000kB
--                                 ->  Subquery Scan on sc  (cost=158100.27..161618.60 rows=175916 width=16) (actual time=2526.994..2790.788 rows=635893 loops=2)
--                                       ->  HashAggregate  (cost=158100.27..159859.43 rows=175916 width=16) (actual time=2526.987..2726.430 rows=635893 loops=2)
--                                             Group Key: song_streams.song_id
--                                             Batches: 1  Memory Usage: 65553kB
--                                             Worker 0:  Batches: 1  Memory Usage: 65553kB
--                                             ->  Seq Scan on song_streams  (cost=0.00..124221.85 rows=6775685 width=8) (actual time=0.049..708.679 rows=6775685 loops=2)
--               ->  Sort  (cost=3632.91..3657.15 rows=9698 width=16) (actual time=49.155..49.933 rows=10235 loops=2)
--                     Sort Key: pc.song_id
--                     Sort Method: quicksort  Memory: 706kB
--                     Worker 0:  Sort Method: quicksort  Memory: 706kB
--                     ->  Subquery Scan on pc  (cost=2796.77..2990.73 rows=9698 width=16) (actual time=43.313..46.006 rows=10288 loops=2)
--                           ->  HashAggregate  (cost=2796.77..2893.75 rows=9698 width=16) (actual time=43.307..44.952 rows=10288 loops=2)
--                                 Group Key: playlist_tracks.song_id
--                                 Batches: 1  Memory Usage: 1425kB
--                                 Worker 0:  Batches: 1  Memory Usage: 1425kB
--                                 ->  Seq Scan on playlist_tracks  (cost=0.00..2171.18 rows=125118 width=8) (actual time=0.039..13.544 rows=125118 loops=2)
--         ->  Index Scan using idx_sag_mv_song_id on song_average_grade_mv sag  (cost=0.43..7.58 rows=1 width=24) (actual time=0.006..0.006 rows=1 loops=1683)
--               Index Cond: (song_id = s.id)
-- Planning Time: 3.163 ms
-- JIT:
--   Functions: 132
-- "  Options: Inlining false, Optimization false, Expressions true, Deforming true"
-- "  Timing: Generation 7.561 ms (Deform 3.504 ms), Inlining 0.000 ms, Optimization 2.789 ms, Emission 73.213 ms, Total 83.563 ms"
-- Execution Time: 3599.404 ms


-- Materializing the view


create materialized view song_stream_counts_mv as
select
    song_id,
    count(*) as streams
from song_streams
group by song_id;


create materialized view song_playlist_counts_mv as
select
    song_id,
    count(*) as saved_in_playlists
from playlist_tracks
group by song_id;


create or replace view song_detailed_info_view_mvs as
select
    s.title as title,
    a.display_name as artist_name,
    coalesce(l.name, 'SOLO') as label_name,
    coalesce(sc.streams, 0) as streams,
    coalesce(alb.title, 'SINGLE') as album_title,
    coalesce(pc.saved_in_playlists, 0) as saved_in_playlists,
    sag.num_reviews,
    ROUND(sag.avg_grade, 2) AS avg_grade
from songs s
left join artists a on a.id = s.owner_artist_id
left join artist_labels al on al.artist_id = a.id
left join labels l on l.id = al.label_id
left join album_tracks at on at.song_id = s.id
left join albums alb on alb.id = at.album_id
left join song_stream_counts_mv sc on sc.song_id = s.id
left join song_playlist_counts_mv pc on pc.song_id = s.id
left join song_average_grade_mv sag on sag.song_id = s.id;


drop index idx_song_stream_counts_mv_song_id,idx_song_playlist_counts_mv_song_id;

create  index idx_song_stream_counts_mv_song_id
on song_stream_counts_mv(song_id);
create  index idx_song_playlist_counts_mv_song_id
on song_playlist_counts_mv(song_id);

explain analyse
select * from song_detailed_info_view_mvs where title='Harmony';

-- WITHOUT INDEXES ON MV

-- Gather  (cost=25188.45..57377.30 rows=2211 width=145) (actual time=113.872..333.525 rows=1683 loops=1)
--   Workers Planned: 3
--   Workers Launched: 3
--   ->  Parallel Hash Right Join  (cost=24188.45..56156.20 rows=713 width=145) (actual time=84.308..207.282 rows=421 loops=4)
--         Hash Cond: (sag.song_id = s.id)
--         ->  Parallel Seq Scan on song_average_grade_mv sag  (cost=0.00..29616.74 rows=625674 width=24) (actual time=0.016..50.181 rows=484897 loops=4)
--         ->  Parallel Hash  (cost=24176.94..24176.94 rows=921 width=85) (actual time=83.322..83.338 rows=421 loops=4)
--               Buckets: 4096  Batches: 1  Memory Usage: 256kB
--               ->  Hash Left Join  (cost=10077.11..24176.94 rows=921 width=85) (actual time=20.990..64.447 rows=421 loops=4)
--                     Hash Cond: (s.id = pc.song_id)
--                     ->  Nested Loop Left Join  (cost=9789.63..23885.95 rows=921 width=77) (actual time=17.300..60.507 rows=421 loops=4)
--                           ->  Nested Loop Left Join  (cost=9789.21..23469.82 rows=921 width=72) (actual time=17.283..57.817 rows=421 loops=4)
--                                 ->  Hash Left Join  (cost=9788.78..16895.77 rows=921 width=64) (actual time=17.245..53.588 rows=421 loops=4)
--                                       Hash Cond: (al.label_id = l.id)
--                                       ->  Nested Loop Left Join  (cost=9775.35..16879.89 rows=921 width=49) (actual time=17.040..53.223 rows=421 loops=4)
--                                             ->  Parallel Hash Left Join  (cost=9775.06..16578.54 rows=921 width=49) (actual time=16.984..51.378 rows=421 loops=4)
--                                                   Hash Cond: (s.owner_artist_id = a.id)
--                                                   ->  Parallel Hash Right Join  (cost=7083.52..13884.59 rows=921 width=37) (actual time=4.483..38.155 rows=421 loops=4)
--                                                         Hash Cond: (sc.song_id = s.id)
--                                                         ->  Parallel Seq Scan on song_stream_counts_mv sc  (cost=0.00..6105.55 rows=264955 width=16) (actual time=0.013..14.911 rows=158973 loops=4)
--                                                         ->  Parallel Hash  (cost=7067.26..7067.26 rows=1301 width=29) (actual time=4.275..4.276 rows=421 loops=4)
--                                                               Buckets: 4096  Batches: 1  Memory Usage: 160kB
--                                                               ->  Parallel Bitmap Heap Scan on songs s  (cost=29.56..7067.26 rows=1301 width=29) (actual time=0.718..3.921 rows=421 loops=4)
--                                                                     Recheck Cond: ((title)::text = 'Harmony'::text)
--                                                                     Heap Blocks: exact=455
--                                                                     ->  Bitmap Index Scan on idx_songs_title  (cost=0.00..29.01 rows=2211 width=0) (actual time=0.386..0.386 rows=1683 loops=1)
--                                                                           Index Cond: ((title)::text = 'Harmony'::text)
--                                                   ->  Parallel Hash  (cost=1956.24..1956.24 rows=58824 width=20) (actual time=12.017..12.018 rows=25000 loops=4)
--                                                         Buckets: 131072  Batches: 1  Memory Usage: 6528kB
--                                                         ->  Parallel Seq Scan on artists a  (cost=0.00..1956.24 rows=58824 width=20) (actual time=0.166..3.968 rows=25000 loops=4)
--                                             ->  Index Scan using idx_artist_labels_artist_id on artist_labels al  (cost=0.29..0.32 rows=1 width=16) (actual time=0.004..0.004 rows=0 loops=1683)
--                                                   Index Cond: (artist_id = a.id)
--                                       ->  Hash  (cost=8.75..8.75 rows=375 width=31) (actual time=0.179..0.180 rows=375 loops=4)
--                                             Buckets: 1024  Batches: 1  Memory Usage: 33kB
--                                             ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=31) (actual time=0.030..0.078 rows=375 loops=4)
--                                 ->  Index Scan using idx_album_tracks_song_id on album_tracks at  (cost=0.43..7.13 rows=1 width=16) (actual time=0.009..0.009 rows=1 loops=1683)
--                                       Index Cond: (song_id = s.id)
--                           ->  Index Scan using albums_pkey on albums alb  (cost=0.42..0.45 rows=1 width=21) (actual time=0.006..0.006 rows=1 loops=1683)
--                                 Index Cond: (id = at.album_id)
--                     ->  Hash  (cost=158.88..158.88 rows=10288 width=16) (actual time=3.568..3.568 rows=10288 loops=4)
--                           Buckets: 16384  Batches: 1  Memory Usage: 611kB
--                           ->  Seq Scan on song_playlist_counts_mv pc  (cost=0.00..158.88 rows=10288 width=16) (actual time=0.022..1.349 rows=10288 loops=4)
-- Planning Time: 135.345 ms
-- Execution Time: 333.811 ms



-- WITH INDEXES ON MV

-- Gather  (cost=11077.54..32384.22 rows=2211 width=121) (actual time=54.782..398.641 rows=1683 loops=1)
--   Workers Planned: 2
--   Workers Launched: 2
--   ->  Nested Loop Left Join  (cost=10077.54..31163.12 rows=921 width=121) (actual time=21.596..89.733 rows=561 loops=3)
--         ->  Hash Left Join  (cost=10077.11..24175.85 rows=921 width=85) (actual time=21.559..81.969 rows=561 loops=3)
--               Hash Cond: (s.id = pc.song_id)
--               ->  Nested Loop Left Join  (cost=9789.63..23885.95 rows=921 width=77) (actual time=17.728..77.745 rows=561 loops=3)
--                     ->  Nested Loop Left Join  (cost=9789.21..23469.82 rows=921 width=72) (actual time=17.704..72.913 rows=561 loops=3)
--                           ->  Hash Left Join  (cost=9788.78..16895.77 rows=921 width=64) (actual time=17.665..65.929 rows=561 loops=3)
--                                 Hash Cond: (al.label_id = l.id)
--                                 ->  Nested Loop Left Join  (cost=9775.35..16879.89 rows=921 width=49) (actual time=17.453..65.470 rows=561 loops=3)
--                                       ->  Parallel Hash Left Join  (cost=9775.06..16578.54 rows=921 width=49) (actual time=17.406..62.421 rows=561 loops=3)
--                                             Hash Cond: (s.owner_artist_id = a.id)
--                                             ->  Parallel Hash Right Join  (cost=7083.52..13884.59 rows=921 width=37) (actual time=1.757..45.712 rows=561 loops=3)
--                                                   Hash Cond: (sc.song_id = s.id)
--                                                   ->  Parallel Seq Scan on song_stream_counts_mv sc  (cost=0.00..6105.55 rows=264955 width=16) (actual time=0.020..18.783 rows=211964 loops=3)
--                                                   ->  Parallel Hash  (cost=7067.26..7067.26 rows=1301 width=29) (actual time=1.352..1.354 rows=561 loops=3)
--                                                         Buckets: 4096  Batches: 1  Memory Usage: 128kB
--                                                         ->  Parallel Bitmap Heap Scan on songs s  (cost=29.56..7067.26 rows=1301 width=29) (actual time=0.615..3.523 rows=1683 loops=1)
--                                                               Recheck Cond: ((title)::text = 'Harmony'::text)
--                                                               Heap Blocks: exact=1623
--                                                               ->  Bitmap Index Scan on idx_songs_title  (cost=0.00..29.01 rows=2211 width=0) (actual time=0.342..0.343 rows=1683 loops=1)
--                                                                     Index Cond: ((title)::text = 'Harmony'::text)
--                                             ->  Parallel Hash  (cost=1956.24..1956.24 rows=58824 width=20) (actual time=14.894..14.895 rows=33333 loops=3)
--                                                   Buckets: 131072  Batches: 1  Memory Usage: 6464kB
--                                                   ->  Parallel Seq Scan on artists a  (cost=0.00..1956.24 rows=58824 width=20) (actual time=0.674..15.758 rows=100000 loops=1)
--                                       ->  Index Scan using idx_artist_labels_artist_id on artist_labels al  (cost=0.29..0.32 rows=1 width=16) (actual time=0.004..0.004 rows=0 loops=1683)
--                                             Index Cond: (artist_id = a.id)
--                                 ->  Hash  (cost=8.75..8.75 rows=375 width=31) (actual time=0.181..0.181 rows=375 loops=3)
--                                       Buckets: 1024  Batches: 1  Memory Usage: 33kB
--                                       ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=31) (actual time=0.038..0.090 rows=375 loops=3)
--                           ->  Index Scan using idx_album_tracks_song_id on album_tracks at  (cost=0.43..7.13 rows=1 width=16) (actual time=0.011..0.012 rows=1 loops=1683)
--                                 Index Cond: (song_id = s.id)
--                     ->  Index Scan using albums_pkey on albums alb  (cost=0.42..0.45 rows=1 width=21) (actual time=0.008..0.008 rows=1 loops=1683)
--                           Index Cond: (id = at.album_id)
--               ->  Hash  (cost=158.88..158.88 rows=10288 width=16) (actual time=3.719..3.720 rows=10288 loops=3)
--                     Buckets: 16384  Batches: 1  Memory Usage: 611kB
--                     ->  Seq Scan on song_playlist_counts_mv pc  (cost=0.00..158.88 rows=10288 width=16) (actual time=0.029..1.493 rows=10288 loops=3)
--         ->  Index Scan using idx_sag_mv_song_id on song_average_grade_mv sag  (cost=0.43..7.58 rows=1 width=24) (actual time=0.012..0.013 rows=1 loops=1683)
--               Index Cond: (song_id = s.id)
-- Planning Time: 3.833 ms
-- Execution Time: 398.864 ms

select count(*) from playlist_tracks;
-- Insert and update WITHOUT INDEX

explain analyze
insert into songs (title, visibility, owner_artist_id, published_by_artist_id)
select 'TEST_INSERT_SONG', 'PUBLIC', id, id
from artists
limit 1;

-- Insert on songs  (cost=0.00..0.04 rows=0 width=0) (actual time=4068.032..4068.033 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.04 rows=1 width=1202) (actual time=4067.729..4067.733 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.02 rows=1 width=80) (actual time=4.059..4.061 rows=1 loops=1)
--               ->  Seq Scan on artists  (cost=0.00..2368.00 rows=100000 width=80) (actual time=4.058..4.058 rows=1 loops=1)
-- Planning Time: 0.127 ms
-- Trigger for constraint songs_owner_artist_id_fkey: time=0.208 calls=1
-- Trigger for constraint songs_published_by_artist_id_fkey: time=0.092 calls=1
-- Trigger for constraint songs_published_by_label_admin_id_fkey: time=0.005 calls=1
-- Execution Time: 4068.532 ms

explain analyze
update songs
set title = title || '_x'
where id = (select id from songs limit 1);


-- Update on songs  (cost=0.46..8.48 rows=0 width=0) (actual time=6865.717..6865.720 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.03 rows=1 width=8) (actual time=0.024..0.025 rows=1 loops=1)
--           ->  Seq Scan on songs songs_1  (cost=0.00..55942.34 rows=1951234 width=8) (actual time=0.023..0.023 rows=1 loops=1)
--   ->  Index Scan using songs_pkey on songs  (cost=0.43..8.45 rows=1 width=522) (actual time=128.120..128.123 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.154 ms
-- Execution Time: 6865.769 ms


explain analyze
insert into album_tracks (album_id, song_id, track_number)
select al.id, s.id, 999999
from albums al
cross join songs s
limit 1;


-- Insert on album_tracks  (cost=0.00..0.02 rows=0 width=0) (actual time=2680.481..2680.485 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.02 rows=1 width=28) (actual time=1.819..1.824 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.01 rows=1 width=20) (actual time=1.807..1.810 rows=1 loops=1)
--               ->  Nested Loop  (cost=0.00..4879513047.84 rows=390356069104 width=20) (actual time=1.806..1.808 rows=1 loops=1)
--                     ->  Seq Scan on songs s  (cost=0.00..55942.34 rows=1951234 width=8) (actual time=0.025..0.025 rows=1 loops=1)
--                     ->  Materialize  (cost=0.00..6741.84 rows=200056 width=8) (actual time=1.778..1.779 rows=1 loops=1)
--                           ->  Seq Scan on albums al  (cost=0.00..5741.56 rows=200056 width=8) (actual time=1.775..1.776 rows=1 loops=1)
-- Planning Time: 0.157 ms
-- Trigger for constraint album_tracks_album_id_fkey: time=0.189 calls=1
-- Trigger for constraint album_tracks_song_id_fkey: time=0.106 calls=1
-- Execution Time: 2680.826 ms


explain analyze
update album_tracks
set song_id = song_id
where id = (select id from album_tracks limit 1);

-- Update on album_tracks  (cost=0.44..8.46 rows=0 width=0) (actual time=996.076..996.078 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.02 rows=1 width=8) (actual time=0.032..0.033 rows=1 loops=1)
--           ->  Seq Scan on album_tracks album_tracks_1  (cost=0.00..23444.16 rows=1351016 width=8) (actual time=0.030..0.031 rows=1 loops=1)
--   ->  Index Scan using album_tracks_pkey on album_tracks  (cost=0.43..8.45 rows=1 width=14) (actual time=946.451..946.454 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 321.927 ms
-- Execution Time: 996.147 ms


explain analyse
insert into artist_labels (artist_id, label_id, active, start_date)
select a.id, l.id, true, current_date
from artists a
cross join labels l
limit 1;

-- Insert on artist_labels  (cost=0.00..0.02 rows=0 width=0) (actual time=1673.350..1673.353 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.02 rows=1 width=33) (actual time=0.722..0.728 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.02 rows=1 width=21) (actual time=0.712..0.715 rows=1 loops=1)
--               ->  Nested Loop  (cost=0.00..564877.69 rows=37500000 width=21) (actual time=0.710..0.712 rows=1 loops=1)
--                     ->  Seq Scan on artists a  (cost=0.00..2368.00 rows=100000 width=8) (actual time=0.687..0.687 rows=1 loops=1)
--                     ->  Materialize  (cost=0.00..10.62 rows=375 width=8) (actual time=0.016..0.017 rows=1 loops=1)
--                           ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=8) (actual time=0.012..0.012 rows=1 loops=1)
-- Planning Time: 0.158 ms
-- Trigger for constraint artist_labels_artist_id_fkey: time=0.213 calls=1
-- Trigger for constraint artist_labels_label_id_fkey: time=0.090 calls=1
-- Execution Time: 1673.706 ms



explain analyze
update artist_labels
set artist_id = artist_id
where id = (select id from artist_labels limit 1);

-- Update on artist_labels  (cost=0.30..8.32 rows=0 width=0) (actual time=0.104..0.105 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.02 rows=1 width=8) (actual time=0.026..0.027 rows=1 loops=1)
--           ->  Seq Scan on artist_labels artist_labels_1  (cost=0.00..521.03 rows=30003 width=8) (actual time=0.025..0.025 rows=1 loops=1)
--   ->  Index Scan using artist_labels_pkey on artist_labels  (cost=0.29..8.30 rows=1 width=14) (actual time=0.046..0.047 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.154 ms
-- Execution Time: 0.144 ms



-- Insert and update with indexes

explain analyze
insert into songs (title, visibility, owner_artist_id, published_by_artist_id)
select 'TEST_INSERT_SONG', 'PUBLIC', id, id
from artists
limit 1;

-- Insert on songs  (cost=0.00..0.04 rows=0 width=0) (actual time=5055.817..5055.819 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.04 rows=1 width=1202) (actual time=0.621..0.625 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.02 rows=1 width=80) (actual time=0.611..0.613 rows=1 loops=1)
--               ->  Seq Scan on artists  (cost=0.00..2368.00 rows=100000 width=80) (actual time=0.610..0.610 rows=1 loops=1)
-- Planning Time: 0.115 ms
-- Trigger for constraint songs_owner_artist_id_fkey: time=0.220 calls=1
-- Trigger for constraint songs_published_by_artist_id_fkey: time=0.089 calls=1
-- Trigger for constraint songs_published_by_label_admin_id_fkey: time=0.006 calls=1
-- Execution Time: 5056.177 ms


explain analyze
update songs
set title = title || '_x'
where id = (select id from songs limit 1);

-- Update on songs  (cost=0.46..8.48 rows=0 width=0) (actual time=166.473..166.474 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.03 rows=1 width=8) (actual time=0.026..0.027 rows=1 loops=1)
--           ->  Seq Scan on songs songs_1  (cost=0.00..55942.35 rows=1951235 width=8) (actual time=0.025..0.025 rows=1 loops=1)
--   ->  Index Scan using songs_pkey on songs  (cost=0.43..8.45 rows=1 width=522) (actual time=166.294..166.296 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.164 ms
-- Execution Time: 166.522 ms

explain analyse
insert into album_tracks (album_id, song_id, track_number)
select al.id, s.id, 999998
from albums al
cross join songs s
limit 1;

-- Insert on album_tracks  (cost=0.00..0.02 rows=0 width=0) (actual time=7629.093..7629.096 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.02 rows=1 width=28) (actual time=1.774..1.779 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.01 rows=1 width=20) (actual time=1.763..1.766 rows=1 loops=1)
--               ->  Nested Loop  (cost=0.00..4879515548.55 rows=390356269160 width=20) (actual time=1.761..1.763 rows=1 loops=1)
--                     ->  Seq Scan on songs s  (cost=0.00..55942.35 rows=1951235 width=8) (actual time=0.023..0.023 rows=1 loops=1)
--                     ->  Materialize  (cost=0.00..6741.84 rows=200056 width=8) (actual time=1.735..1.736 rows=1 loops=1)
--                           ->  Seq Scan on albums al  (cost=0.00..5741.56 rows=200056 width=8) (actual time=1.733..1.733 rows=1 loops=1)
-- Planning Time: 0.162 ms
-- Trigger for constraint album_tracks_album_id_fkey: time=0.293 calls=1
-- Trigger for constraint album_tracks_song_id_fkey: time=10.782 calls=1
-- Execution Time: 7640.218 ms


explain analyze
update album_tracks
set song_id = song_id
where id = (select id from album_tracks limit 1);


-- Update on album_tracks  (cost=0.44..8.46 rows=0 width=0) (actual time=327.266..327.268 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.02 rows=1 width=8) (actual time=0.037..0.039 rows=1 loops=1)
--           ->  Seq Scan on album_tracks album_tracks_1  (cost=0.00..23444.17 rows=1351017 width=8) (actual time=0.036..0.037 rows=1 loops=1)
--   ->  Index Scan using album_tracks_pkey on album_tracks  (cost=0.43..8.45 rows=1 width=14) (actual time=0.078..0.081 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.221 ms
-- Execution Time: 327.351 ms


explain analyse
insert into artist_labels (artist_id, label_id, active, start_date)
select a.id, l.id, true, current_date
from artists a
cross join labels l
limit 1;

-- Insert on artist_labels  (cost=0.00..0.02 rows=0 width=0) (actual time=1838.535..1838.538 rows=0 loops=1)
-- "  ->  Subquery Scan on ""*SELECT*""  (cost=0.00..0.02 rows=1 width=33) (actual time=1838.166..1838.172 rows=1 loops=1)"
--         ->  Limit  (cost=0.00..0.02 rows=1 width=21) (actual time=372.693..372.696 rows=1 loops=1)
--               ->  Nested Loop  (cost=0.00..564877.69 rows=37500000 width=21) (actual time=372.691..372.693 rows=1 loops=1)
--                     ->  Seq Scan on artists a  (cost=0.00..2368.00 rows=100000 width=8) (actual time=372.621..372.621 rows=1 loops=1)
--                     ->  Materialize  (cost=0.00..10.62 rows=375 width=8) (actual time=0.061..0.062 rows=1 loops=1)
--                           ->  Seq Scan on labels l  (cost=0.00..8.75 rows=375 width=8) (actual time=0.056..0.056 rows=1 loops=1)
-- Planning Time: 0.151 ms
-- Trigger for constraint artist_labels_artist_id_fkey: time=0.160 calls=1
-- Trigger for constraint artist_labels_label_id_fkey: time=0.132 calls=1
-- Execution Time: 1838.980 ms


explain analyze
update artist_labels
set artist_id = artist_id
where id = (select id from artist_labels limit 1);


-- Update on artist_labels  (cost=0.30..8.32 rows=0 width=0) (actual time=2762.655..2762.658 rows=0 loops=1)
--   InitPlan 1
--     ->  Limit  (cost=0.00..0.02 rows=1 width=8) (actual time=0.029..0.030 rows=1 loops=1)
--           ->  Seq Scan on artist_labels artist_labels_1  (cost=0.00..521.05 rows=30005 width=8) (actual time=0.028..0.028 rows=1 loops=1)
--   ->  Index Scan using artist_labels_pkey on artist_labels  (cost=0.29..8.30 rows=1 width=14) (actual time=0.055..0.058 rows=1 loops=1)
--         Index Cond: (id = (InitPlan 1).col1)
-- Planning Time: 0.186 ms
-- Execution Time: 2762.736 ms


-- view #8
create or replace view streams_history as
select u.id as user_id,
    u.username,
    s.id as song_id,
    s.title,
    ss.streamed_at,
    ps.listened_ms
from users u
join song_streams ss on ss.user_id=u.id
join songs s on s.id=ss.song_id
join playback_sessions ps on ps.id=ss.playback_session_id;


explain analyse
select *
from streams_history
where username='adriana_klein_511'
order by streamed_at desc;


-- Sort  (cost=52.13..52.15 rows=7 width=58) (actual time=0.333..0.335 rows=15 loops=1)
--   Sort Key: ss.streamed_at DESC
--   Sort Method: quicksort  Memory: 26kB
--   ->  Nested Loop  (cost=1.72..52.03 rows=7 width=58) (actual time=0.072..0.316 rows=15 loops=1)
--         ->  Nested Loop  (cost=1.28..48.40 rows=7 width=62) (actual time=0.061..0.195 rows=15 loops=1)
--               ->  Nested Loop  (cost=0.86..45.09 rows=7 width=49) (actual time=0.049..0.094 rows=15 loops=1)
--                     ->  Index Scan using users_username_key on users u  (cost=0.42..8.44 rows=1 width=25) (actual time=0.029..0.030 rows=1 loops=1)
--                           Index Cond: ((username)::text = 'adriana_klein_511'::text)
--                     ->  Index Scan using idx_song_streams_user_id on song_streams ss  (cost=0.43..36.57 rows=8 width=32) (actual time=0.014..0.056 rows=15 loops=1)
--                           Index Cond: (user_id = u.id)
--               ->  Index Scan using songs_pkey on songs s  (cost=0.43..0.47 rows=1 width=21) (actual time=0.006..0.006 rows=1 loops=15)
--                     Index Cond: (id = ss.song_id)
--         ->  Index Scan using playback_sessions_pkey on playback_sessions ps  (cost=0.43..0.52 rows=1 width=12) (actual time=0.007..0.007 rows=1 loops=15)
--               Index Cond: (id = ss.playback_session_id)
-- Planning Time: 91.388 ms
-- Execution Time: 0.404 ms
