INSERT INTO Users (username, email, password, full_name, last_login)
SELECT
    substr(md5(random()::text), 1, 12),
    substr(md5(random()::text), 1, 10) || '@gmail.com',
    'password123',
    'John Doe',
    now()
FROM generate_series(1, 1000000)
ON CONFLICT DO NOTHING;


INSERT INTO Roles(role_name)
VALUES ('ADMIN'),
       ('FREE_LISTENER'),
       ('PREMIUM_LISTENER'),
       ('ARTIST'),
       ('LABEL_ADMIN');


INSERT INTO Permissions (action, resource_type, scope) VALUES
('PLAY', 'SONG', 'PUBLIC'),
('PLAY', 'SONG', 'SHARED'),
('PLAY', 'SONG', 'OWN'),
('VIEW', 'SONG', 'PUBLIC'),
('VIEW', 'SONG', 'SHARED'),
('VIEW', 'SONG', 'OWN'),
('CREATE', 'SONG', 'OWN'),
('EDIT', 'SONG', 'OWN'),
('DELETE', 'SONG', 'OWN'),
('EDIT', 'SONG', 'ANY'),
('DELETE', 'SONG', 'ANY'),

('VIEW', 'ALBUM', 'PUBLIC'),
('VIEW', 'ALBUM', 'SHARED'),
('VIEW', 'ALBUM', 'OWN'),
('CREATE', 'ALBUM', 'OWN'),
('EDIT', 'ALBUM', 'OWN'),
('DELETE', 'ALBUM', 'OWN'),
('EDIT', 'ALBUM', 'ANY'),
('DELETE', 'ALBUM', 'ANY'),

('VIEW', 'PLAYLIST', 'PUBLIC'),
('VIEW', 'PLAYLIST', 'SHARED'),
('VIEW', 'PLAYLIST', 'OWN'),
('CREATE', 'PLAYLIST', 'OWN'),
('EDIT', 'PLAYLIST', 'OWN'),
('DELETE', 'PLAYLIST', 'OWN'),
('ADD_SONG', 'PLAYLIST', 'OWN'),
('REMOVE_SONG', 'PLAYLIST', 'OWN'),
('SHARE', 'PLAYLIST', 'OWN'),
('DELETE', 'PLAYLIST', 'ANY');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
         JOIN permissions p ON (
    -- SONG
    (p.action = 'PLAY' AND p.resource_type = 'SONG' AND p.scope = 'PUBLIC' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'PLAY' AND p.resource_type = 'SONG' AND p.scope = 'SHARED' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'PLAY' AND p.resource_type = 'SONG' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR

    (p.action = 'VIEW' AND p.resource_type = 'SONG' AND p.scope = 'PUBLIC' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'VIEW' AND p.resource_type = 'SONG' AND p.scope = 'SHARED' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'VIEW' AND p.resource_type = 'SONG' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR

    (p.action = 'CREATE' AND p.resource_type = 'SONG' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'EDIT' AND p.resource_type = 'SONG' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'DELETE' AND p.resource_type = 'SONG' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR

    (p.action = 'EDIT' AND p.resource_type = 'SONG' AND p.scope = 'ANY' AND r.role_name IN ('ADMIN','LABEL_ADMIN')) OR
    (p.action = 'DELETE' AND p.resource_type = 'SONG' AND p.scope = 'ANY' AND r.role_name IN ('ADMIN','LABEL_ADMIN')) OR

        -- ALBUM
    (p.action = 'VIEW' AND p.resource_type = 'ALBUM' AND p.scope = 'PUBLIC' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'VIEW' AND p.resource_type = 'ALBUM' AND p.scope = 'SHARED' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'VIEW' AND p.resource_type = 'ALBUM' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR

    (p.action = 'CREATE' AND p.resource_type = 'ALBUM' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'EDIT' AND p.resource_type = 'ALBUM' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'DELETE' AND p.resource_type = 'ALBUM' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR

    (p.action = 'EDIT' AND p.resource_type = 'ALBUM' AND p.scope = 'ANY' AND r.role_name IN ('ADMIN','LABEL_ADMIN')) OR
    (p.action = 'DELETE' AND p.resource_type = 'ALBUM' AND p.scope = 'ANY' AND r.role_name IN ('ADMIN','LABEL_ADMIN')) OR

        -- PLAYLIST
    (p.action = 'VIEW' AND p.resource_type = 'PLAYLIST' AND p.scope = 'PUBLIC' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'VIEW' AND p.resource_type = 'PLAYLIST' AND p.scope = 'SHARED' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'VIEW' AND p.resource_type = 'PLAYLIST' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR

    (p.action = 'CREATE' AND p.resource_type = 'PLAYLIST' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'EDIT' AND p.resource_type = 'PLAYLIST' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'DELETE' AND p.resource_type = 'PLAYLIST' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR

    (p.action = 'ADD_SONG' AND p.resource_type = 'PLAYLIST' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'REMOVE_SONG' AND p.resource_type = 'PLAYLIST' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'SHARE' AND p.resource_type = 'PLAYLIST' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR

    (p.action = 'DELETE' AND p.resource_type = 'PLAYLIST' AND p.scope = 'ANY' AND r.role_name IN ('ADMIN','LABEL_ADMIN'))
    );


INSERT INTO Labels (name)
SELECT (
           substr(md5(random()::text), 1, 12)

           )
FROM generate_series(1, 375);


INSERT INTO Artists (user_id, display_name)
SELECT
    id,
    substr(md5(random()::text), 1, 12)
FROM Users
ORDER BY id
LIMIT 100000
ON CONFLICT DO NOTHING;



WITH selected_users AS (
    SELECT id, row_number() OVER (ORDER BY id) AS rn
    FROM Users
    ORDER BY id
    OFFSET 100000
        LIMIT 375
)
INSERT INTO Label_Admins (label_id, user_id)
SELECT
    rn-100000 AS label_id,
    id AS user_id
FROM selected_users
ON CONFLICT DO NOTHING;


INSERT INTO User_Roles (user_id, role_id)

SELECT id, 4
FROM Users
WHERE id BETWEEN 1 AND 100000

UNION ALL

SELECT id, 5
FROM Users
WHERE id BETWEEN 100001 AND 100375

UNION ALL

SELECT 1000000, 1

UNION ALL

SELECT
    id,
    CASE
        WHEN (row_number() OVER (ORDER BY id)) % 3 = 0 THEN 3
        ELSE 2
        END
FROM Users
WHERE id BETWEEN 100376 AND 999999;


-- with normal_listeners as
--     (select id
--      from users
--      EXCEPT
--      (select user_id
--       from label_admins
--       union
--       select user_id
--       from artists))
--
--
-- select distinct r.role_name from users u
--
-- join user_roles ur on u.id = ur.user_id
-- join roles r on r.id=ur.role_id
-- join normal_listeners nl on  nl.id=u.id
-- where u.id<>1000000;


WITH generated AS (
    SELECT
        -- follower
        CASE
            WHEN random() < 0.9 THEN
                floor(random() * (1000000 - 100375))::bigint + 100376
            ELSE
                floor(random() * 100000)::bigint + 1
            END AS follower_user_id,

        -- followed
        CASE
            WHEN random() < 0.85 THEN  -- artists
                CASE
                    WHEN random() < 0.8 THEN
                        -- top 40 artists
                        floor(random() * 40)::bigint + 1
                    ELSE
                        -- remaining
                        floor(random() * (100000 - 40))::bigint + 41
                    END
            ELSE
                -- listeners
                floor(random() * (1000000 - 100375))::bigint + 100376
            END AS followed_user_id

    FROM generate_series(1, 200000)
)

INSERT INTO Follows (follower_user_id, followed_user_id)
SELECT DISTINCT *
FROM generated
WHERE follower_user_id <> followed_user_id
LIMIT 100000;




WITH artist_followers AS (
    SELECT
        a.id AS artist_id,
        COUNT(f.follower_user_id) AS follower_count
    FROM Artists a
             LEFT JOIN Follows f
                       ON f.followed_user_id = a.user_id
    GROUP BY a.id
),
     ranked AS (
         SELECT *,
                NTILE(10) OVER (ORDER BY follower_count DESC) AS popularity_bucket
         FROM artist_followers
     ),
     selected AS (
         SELECT *
         FROM ranked
         WHERE popularity_bucket <= 3
     )
INSERT INTO Artist_Labels (artist_id, label_id, active, start_date, end_date)
SELECT
    s.artist_id,
    s.artist_id%375+1,
    TRUE,
    CURRENT_DATE - (random() * 3650)::int,
    NULL
FROM selected s;


select label_id,count(*) from artist_labels
group by label_id;

-- delete from artist_labels;

select count(*) from artist_labels;


WITH artist_followers AS (
    SELECT
        a.id AS artist_id,
        a.user_id,
        COUNT(f.follower_user_id) AS follower_count
    FROM Artists a
             LEFT JOIN Follows f
                       ON f.followed_user_id = a.user_id
    GROUP BY a.id, a.user_id
),
     artist_labels_active AS (
         SELECT al.artist_id, al.label_id
         FROM Artist_Labels al
         WHERE al.active = TRUE
     ),
     artist_full AS (
         SELECT
             af.artist_id,
             af.follower_count,
             al.label_id,
             la.id AS label_admin_id
         FROM artist_followers af
                  LEFT JOIN artist_labels_active al
                            ON af.artist_id = al.artist_id
                  LEFT JOIN Label_Admins la
                            ON la.label_id = al.label_id
     ),
     expanded AS (
         SELECT
             af.*,
             generate_series(
                     1,
                     CASE
                         WHEN af.follower_count > 1200 THEN 100
                         ELSE (floor(random() * 40))::int -- 0-39
                         END
             ) AS song_num
         FROM artist_full af
     )
INSERT INTO Songs (
    title,
    visibility,
    owner_artist_id,
    published_by_artist_id,
    published_by_label_admin_id,
    genre
)
SELECT
    -- random title
    'Song_' || artist_id || '_' || song_num,

    -- random visibility
    (ARRAY['PUBLIC','PRIVATE'])[floor(random()*2)+1],

    -- owner
    artist_id,

    -- published_by_artist_id (ONLY if no label)
    CASE
        WHEN label_id IS NULL THEN artist_id
        ELSE NULL
        END,

    -- published_by_label_admin_id (ONLY if label exists)
    CASE
        WHEN label_id IS NOT NULL THEN label_admin_id
        ELSE NULL
        END,

    NULL
FROM expanded;


WITH artist_followers AS (
    SELECT
        a.id AS artist_id,
        COUNT(f.follower_user_id) AS follower_count
    FROM Artists a
             LEFT JOIN Follows f
                       ON f.followed_user_id = a.user_id
    GROUP BY a.id
),
     artist_labels_active AS (
         SELECT artist_id, label_id
         FROM Artist_Labels
         WHERE active = TRUE
     ),
     artist_full AS (
         SELECT
             af.artist_id,
             af.follower_count,
             al.label_id,
             la.id AS label_admin_id
         FROM artist_followers af
                  LEFT JOIN artist_labels_active al
                            ON af.artist_id = al.artist_id
                  LEFT JOIN Label_Admins la
                            ON la.label_id = al.label_id
     ),
     expanded AS (
         SELECT
             af.*,
             generate_series(
                     1,
                     CASE
                         WHEN af.follower_count > 1200
                             THEN (5 + floor(random() * 6))::int   -- 5–10
                         ELSE (1 + floor(random() * 3))::int       -- 1–3
                         END
             ) AS album_num
         FROM artist_full af
     )
INSERT INTO Albums (
    title,
    visibility,
    owner_artist_id,
    published_by_artist_id,
    published_by_label_admin_id
)
SELECT
    'Album_' || artist_id || '_' || album_num,

    (ARRAY['PUBLIC','PRIVATE'])[floor(random()*2)+1],

    artist_id,

    -- solo artists publish themselves
    CASE
        WHEN label_id IS NULL THEN artist_id
        ELSE NULL
        END,

    -- label artists published by label
    CASE
        WHEN label_id IS NOT NULL THEN label_admin_id
        ELSE NULL
        END

FROM expanded
WHERE (label_id IS NULL OR label_admin_id IS NOT NULL);


select count(*) from(
                        select owner_artist_id,count(*) from albums
                        group by owner_artist_id);



-- select count(f.follower_user_id)
-- from albums a
-- join follows f on a.owner_artist_id=f.followed_user_id
-- group by a.owner_artist_id
-- order by count(f.follower_user_id)desc ;



WITH song_album_match AS (
    SELECT
        s.id AS song_id,
        al.id AS album_id,

        ROW_NUMBER() OVER (
            PARTITION BY s.id
            ORDER BY random()
            ) AS rn

    FROM Songs s
             JOIN Albums al
                  ON al.owner_artist_id = s.owner_artist_id
                      AND (
                         (al.published_by_artist_id IS NOT NULL AND s.published_by_artist_id IS NOT NULL)
                             OR (al.published_by_label_admin_id IS NOT NULL AND s.published_by_label_admin_id IS NOT NULL)
                         )
),
     chosen AS (
         -- pick ONE album per song
         SELECT song_id, album_id
         FROM song_album_match
         WHERE rn = 1
     ), album_limits AS (
    SELECT
        id AS album_id,
        (8 + floor(random() * 8))::int AS max_tracks
    FROM Albums
),
     ranked AS (
         SELECT
             c.*,
             ROW_NUMBER() OVER (
                 PARTITION BY c.album_id
                 ORDER BY random()
                 ) AS rn
         FROM chosen c
     ),
     limited AS (
         SELECT r.*
         FROM ranked r
                  JOIN album_limits l ON r.album_id = l.album_id
         WHERE r.rn <= l.max_tracks
     )
INSERT INTO Album_Tracks (album_id, song_id, track_number)
SELECT
    album_id,
    song_id,
    ROW_NUMBER() OVER (
        PARTITION BY album_id
        ORDER BY rn
        )
FROM limited;

select *
from album_tracks at1
where exists(
    select 1
    from album_tracks at2
    where at1.song_id=at2.song_id
      and at1.album_id<>at2.album_id

);

select *
from album_tracks limit 20;

select count(*)
from (select id
      from songs
      except
      select s.id from songs s
                           join album_tracks at on at.song_id=s.id) as sisai;



INSERT INTO Playlists (playlist_name, visibility, creator_user_id)
SELECT
    'Playlist_' || (floor(random() * 899999)::int + 100001) || '_' || gs,
    CASE WHEN random() < 0.7 THEN 'PUBLIC' ELSE 'PRIVATE' END,
    floor(random() * 899999)::int + 100001
FROM generate_series(1, 10000) gs;


select * from playlists;

-- delete from playlists;
select distinct rnd
from users
         cross join lateral (
    select random() as rnd from albums
    limit 10
    ) as ar

limit 100;


WITH non_artist_users AS (
    SELECT u.id
    FROM Users u
             LEFT JOIN Artists a ON u.id = a.user_id
    WHERE a.user_id IS NULL
),

-- shuffle users once
     shuffled_users AS (
         SELECT id, row_number() OVER () AS rn
         FROM non_artist_users
         ORDER BY random()
     ),

     user_count AS (
         SELECT count(*) AS cnt FROM shuffled_users
     ),

     playlist_sample AS (
         SELECT id AS playlist_id, creator_user_id
         FROM Playlists
         ORDER BY random()
         LIMIT 5000
     ),

     expanded AS (
         SELECT
             p.playlist_id,
             p.creator_user_id,

             generate_series(
                     1,
                     GREATEST(
                             1,
                             LEAST(
                                     20,
                                     ((random() + random() + random()) * 5)::int
                             )
                     )
             ) AS save_instance
         FROM playlist_sample p
     ),

-- ✅ compute row_number HERE (legal)
     expanded_numbered AS (
         SELECT
             e.*,
             row_number() OVER () AS rn
         FROM expanded e
     ),
     assigned AS (
         SELECT
             e.playlist_id,
             u.id AS saved_by
         FROM expanded_numbered e
                  JOIN user_count uc ON TRUE
                  JOIN shuffled_users u
                       ON u.rn = ((e.rn % uc.cnt) + 1)
         WHERE u.id <> e.creator_user_id
     )

INSERT INTO Saved_Playlists (playlist_id, saved_by)
SELECT DISTINCT playlist_id, saved_by
FROM assigned
LIMIT 5000;

select saved_by,count(*)
from saved_playlists
group by saved_by
order by count(*)desc ;

INSERT INTO playlist_tracks (playlist_id, song_id)
SELECT p.id,
       s.id
FROM Playlists p
    CROSS JOIN LATERAL (
    SELECT id
    FROM Songs TABLESAMPLE SYSTEM (0.5)   -- sample ~0.5% (~10k rows)
    ORDER BY random() * (1.0 / sqrt(id)) + p.id * 0
    LIMIT (5 + floor(random() * 16))
    ) s;

WITH song_count AS (
    SELECT COUNT(*) AS cnt FROM Songs
)
INSERT INTO Reviews (user_id, song_id, grade)
SELECT
    (100001 + floor(random() * (999999 - 100001 + 1)))::bigint AS user_id,
    (1 + floor(random() * sc.cnt))::bigint AS song_id,
    (1 + floor(random() * 5))::int AS grade
FROM generate_series(1, 100000),
    song_count sc;



WITH song_count AS (
    SELECT COUNT(*) AS cnt FROM Songs
),

     generated AS (
         SELECT
             user_id,
             song_id,
             started_at,
             listened_ms,
             listened_ms AS last_position_ms
         FROM (
                  SELECT
                      (100001 + floor(random() * (999999 - 100001 + 1)))::bigint AS user_id,

                      CASE
                          WHEN random() < 0.6 THEN
                              floor(random() * (cnt * 0.05))::bigint + 1
                          WHEN random() < 0.85 THEN
                              floor(random() * (cnt * 0.15))::bigint + (cnt * 0.05)::bigint + 1
                          ELSE
                              floor(random() * (cnt * 0.80))::bigint + (cnt * 0.20)::bigint + 1
                          END AS song_id,

                      NOW() - (random() * INTERVAL '6 months') AS started_at,

                      -- computed once per row
                      (20 + floor(random() * 31))::int AS listened_ms

                  FROM generate_series(1, 1500000), song_count
              ) t
     )

INSERT INTO Playback_Sessions (
    user_id,
    song_id,
    started_at,
    listened_ms,
    last_position_ms
)
SELECT *
FROM generated;

INSERT INTO Song_Streams (
    playback_session_id,
    song_id,
    streamed_at
)
SELECT
    ps.id,
    ps.song_id,
    ps.started_at
FROM Playback_Sessions ps
WHERE ps.listened_ms >= 30;

insert into song_relationships (source_song_id, target_song_id, relationship_type)
VALUES (1951937, 1951936, 'REMIX'),
       (1, 2, 'REMIX');

insert into song_contributors (song_id, artist_id, role, credit_order)
VALUES
    (82183, 71535, 'BACK VOCAL', 2),
    (82183, 84285, 'PRODUCER', 3);

-- create shared playlist for user 100002
insert into playlists (visibility, creator_user_id, playlist_name, description)
values ('SHARED', 100002, 'shared playlist', 'this is a shared playlist');

-- add some songs to the new shared playlist
insert into playlist_tracks (song_id, playlist_id)
VALUES (1, 10001), (2, 10001), (3, 10001);

-- give VIEW PLAYLIST access to user 100003
insert into resource_shares (playlist_id, user_id, permission_id)
values (10001, 100003, 21);
