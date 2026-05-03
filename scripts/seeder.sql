-- 1M users 
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

-- this table stores predefined role permissions
-- for example 
-- (p.action = 'EDIT' AND p.resource_type = 'SONG' AND p.scope = 'ANY' AND r.role_name IN ('ADMIN','LABEL_ADMIN')) OR
-- means that only admin and label admin users can edit a song with a scope any
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


-- 375 labels with a random name
INSERT INTO Labels (name)
SELECT (
    substr(md5(random()::text), 1, 12)
)
FROM generate_series(1, 375);


-- 100K artists 
-- user_id-s 0-100.000 are artists
INSERT INTO Artists (user_id, display_name)
SELECT
    id,
    substr(md5(random()::text), 1, 12)
FROM Users
ORDER BY id
LIMIT 100000
ON CONFLICT DO NOTHING;


-- users 
-- user_id-s 100.001-100.375 are label admins
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


-- add the ARTIST role to users with ids 1-100K
-- add the LABEL_ADMIN role to users with ids 100.001-100.375
-- add the ADMIN role to user with user_id 1000000
-- all other users (100.376-999.999) have either a PREMIUM_LISTENER or FREE_LISTENER role

WITH roles_cte AS (
    SELECT
        MAX(CASE WHEN role_name = 'ARTIST' THEN id END) AS artist_id,
        MAX(CASE WHEN role_name = 'LABEL_ADMIN' THEN id END) AS label_admin_id,
        MAX(CASE WHEN role_name = 'PREMIUM_LISTENER' THEN id END) AS premium_id,
        MAX(CASE WHEN role_name = 'FREE_LISTENER' THEN id END) AS free_id
    FROM Roles
)

INSERT INTO User_Roles (user_id, role_id)
SELECT u.id, r.artist_id
FROM Users u
CROSS JOIN roles_cte r
WHERE u.id BETWEEN 1 AND 100000

UNION ALL

SELECT u.id, r.label_admin_id
FROM Users u
CROSS JOIN roles_cte r
WHERE u.id BETWEEN 100001 AND 100375

UNION ALL

SELECT 1000000, 1

UNION ALL

SELECT
    u.id,
    CASE
        WHEN (row_number() OVER (ORDER BY u.id)) % 3 = 0 THEN r.premium_id
        ELSE r.free_id
    END
FROM Users u
CROSS JOIN roles_cte r
WHERE u.id BETWEEN 100376 AND 999999;

-- 200K random follower-followed pairs with a bias
-- most of the followers are listeners and most follow a group of 40 artists to simulate "more popular artists"
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



-- assign the 30% top-followed artists to labels
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


-- first each artist is enriched with popularity and context about the labels
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
        generate_series(1,
        CASE
            WHEN af.follower_count > 1200 THEN 100
            ELSE (floor(random() * 40))::int -- 0-39
        END
) AS song_num
    FROM artist_full af
),
numbered AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY artist_id, song_num) AS rn,
        COUNT(*) OVER () AS total_cnt
    FROM expanded
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
    'Song_' || artist_id || '_' || song_num,
    -- first 25% of songs are private, the rest public
    CASE
        WHEN rn <= total_cnt * 0.25 THEN 'PRIVATE'
        ELSE 'PUBLIC'
    END,
    artist_id,
    CASE
        WHEN label_id IS NULL THEN artist_id
        ELSE NULL
        END,
    CASE
        WHEN label_id IS NOT NULL THEN label_admin_id
        ELSE NULL
        END,
    NULL
FROM numbered;

-- assign songs to albums by giving more albums to more popular artists
WITH artist_followers AS (
    SELECT
        a.id AS artist_id,
        COUNT(f.follower_user_id) AS follower_count
    FROM Artists a
    LEFT JOIN Follows f ON f.followed_user_id = a.user_id
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
    LEFT JOIN artist_labels_active al ON af.artist_id = al.artist_id
    LEFT JOIN Label_Admins la ON la.label_id = al.label_id
),
expanded AS (
    SELECT
    af.*,
    generate_series(
        1,
        CASE
            WHEN af.follower_count > 1200
            THEN (5 + floor(random() * 6))::int   -- 5–10
            ELSE (1 + floor(random() * 3))::int   -- 1–3
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


WITH album_requirements AS (
    -- how many tracks each album needs and get a sequence for the artist's albums
    SELECT
        id AS album_id,
        owner_artist_id,
        (5 + floor(random() * 12))::int AS needed,
        ROW_NUMBER() OVER (PARTITION BY owner_artist_id ORDER BY id) as album_seq
    FROM Albums
),
album_ranges AS (
    -- create a start and end song index for each album
    -- e.g. Album 1: 1-10, Album 2: 11-25, etc.
    SELECT
        *,
        COALESCE(SUM(needed) OVER (PARTITION BY owner_artist_id ORDER BY album_seq ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) + 1 AS range_start,
        SUM(needed) OVER (PARTITION BY owner_artist_id ORDER BY album_seq) AS range_end
    FROM album_requirements
),
artist_songs AS (
    -- rank every song globally per artist
    SELECT
        id AS song_id,
        owner_artist_id,
        ROW_NUMBER() OVER (PARTITION BY owner_artist_id ORDER BY random()) as global_song_rank
    FROM Songs
),
final_assignment AS (
    -- match the song rank to the album range
    -- this ensures a song with rank 5 ONLY fits in the album covering range 1-10
    SELECT
        r.album_id,
        s.song_id,
        (s.global_song_rank - r.range_start + 1) AS track_number,
        r.needed
    FROM album_ranges r
    JOIN artist_songs s
      ON s.owner_artist_id = r.owner_artist_id
     AND s.global_song_rank BETWEEN r.range_start AND r.range_end
),
validation AS (
    -- count how many tracks we actually found for each album
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY album_id) as actual_count
    FROM final_assignment
)

INSERT INTO Album_Tracks (album_id, song_id, track_number)
SELECT album_id, song_id, track_number
FROM validation
WHERE actual_count >= 5;


-- 10K playlists
INSERT INTO Playlists (playlist_name, visibility, creator_user_id)
SELECT
    'Playlist_' || (floor(random() * 899624)::int + 100376) || '_' || gs,
    CASE WHEN random() < 0.7 THEN 'PUBLIC' ELSE 'PRIVATE' END,
    floor(random() * 899624)::int + 100376
FROM generate_series(1, 10000) gs;

-- insert 5K records into Saved_Playlists
-- 1-20 saves per playlist
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


-- todo: check logic!
expanded AS (
    SELECT
        p.playlist_id,
        p.creator_user_id,
        generate_series(
                1, GREATEST(
                    1, LEAST(20, ((random() + random() + random()) * 5)::int
                )
            )
        ) AS save_instance
    FROM playlist_sample p
),

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

-- assign ~125K songs to playlists by sampling random songs 
INSERT INTO playlist_tracks (playlist_id, song_id)
SELECT p.id,
       s.id
FROM Playlists p
CROSS JOIN LATERAL (
    SELECT id
    FROM Songs TABLESAMPLE SYSTEM (0.5)  -- sample ~0.5% (~10k rows)
    ORDER BY random() * (1.0 / sqrt(id)) + p.id * 0 -- p.id * 0 used for forcing postgres to recompute this instead of reusing the same result
    LIMIT (5 + floor(random() * 16))
) s;

-- 100K reviews
WITH song_count AS (
    SELECT COUNT(*) AS cnt FROM Songs
)
INSERT INTO Reviews (user_id, song_id, grade)
SELECT
    (100376 + floor(random() * (999999 - 100376 + 1)))::bigint AS user_id,
    (1 + floor(random() * sc.cnt))::bigint AS song_id,
    (1 + floor(random() * 5))::int AS grade
FROM generate_series(1, 100000),
    song_count sc;


-- 1.5M playback sessions
-- top ~5% of songs are more favored to simulate "more popular" songs, a medium tier gets moderate attention while the rest receive very few plays
-- timestamps are randomly distributed across the last 6 months and durations are 20-50s
-- only public songs are eligible for playback sessions

WITH public_songs AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
    FROM Songs
    WHERE visibility = 'PUBLIC'
),
public_song_count AS (
    SELECT COUNT(*) AS cnt FROM public_songs
),
generated AS (
    SELECT
        t.user_id,
        ps.id AS song_id,
        t.started_at,
        t.listened_ms,
        t.listened_ms AS last_position_ms
    FROM (
        SELECT
            (100376 + floor(random() * (999999 - 100376 + 1)))::bigint AS user_id,

            CASE
                WHEN random() < 0.6 THEN
                    floor(random() * (cnt * 0.05))::bigint + 1
                WHEN random() < 0.85 THEN
                    floor(random() * (cnt * 0.15))::bigint + (cnt * 0.05)::bigint + 1
                ELSE
                    floor(random() * (cnt * 0.80))::bigint + (cnt * 0.20)::bigint + 1
                END AS song_rn,

            NOW() - (random() * INTERVAL '6 months') AS started_at,

            -- computed once per row
            (20000 + floor(random() * 31000))::int AS listened_ms

        FROM generate_series(1, 1500000), public_song_count
    ) t
    JOIN public_songs ps ON ps.rn = t.song_rn
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


-- all sessions that ran for more than 30s are inserted into the songs stream table
-- this is business logic that will later be enforced with a trigger or a job
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
WHERE ps.listened_ms >= 30000;

-- example song relationship
insert into song_relationships (source_song_id, target_song_id, relationship_type)
VALUES (1951937, 1951936, 'REMIX'),
       (1, 2, 'REMIX');

-- example song contribution
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
