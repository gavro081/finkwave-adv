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
    -- Song
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

    -- Album
    (p.action = 'VIEW' AND p.resource_type = 'ALBUM' AND p.scope = 'PUBLIC' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'VIEW' AND p.resource_type = 'ALBUM' AND p.scope = 'SHARED' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN','FREE_LISTENER','PREMIUM_LISTENER')) OR
    (p.action = 'VIEW' AND p.resource_type = 'ALBUM' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR

    (p.action = 'CREATE' AND p.resource_type = 'ALBUM' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'EDIT' AND p.resource_type = 'ALBUM' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR
    (p.action = 'DELETE' AND p.resource_type = 'ALBUM' AND p.scope = 'OWN' AND r.role_name IN ('ADMIN','ARTIST','LABEL_ADMIN')) OR

    (p.action = 'EDIT' AND p.resource_type = 'ALBUM' AND p.scope = 'ANY' AND r.role_name IN ('ADMIN','LABEL_ADMIN')) OR
    (p.action = 'DELETE' AND p.resource_type = 'ALBUM' AND p.scope = 'ANY' AND r.role_name IN ('ADMIN','LABEL_ADMIN')) OR

    -- Playlist
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


