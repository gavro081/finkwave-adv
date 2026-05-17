DROP TABLE IF EXISTS Reviews CASCADE;
DROP TABLE IF EXISTS Song_Streams CASCADE;
DROP TABLE IF EXISTS Playback_Sessions CASCADE;
DROP TABLE IF EXISTS Song_Contributors CASCADE;
DROP TABLE IF EXISTS Song_Relationships CASCADE;
DROP TABLE IF EXISTS Song_Contents CASCADE;
DROP TABLE IF EXISTS Playlist_Tracks CASCADE;
DROP TABLE IF EXISTS Album_Tracks CASCADE;
DROP TABLE IF EXISTS Songs CASCADE;
DROP TABLE IF EXISTS Albums CASCADE;
DROP TABLE IF EXISTS Saved_Playlists CASCADE;
DROP TABLE IF EXISTS Playlists CASCADE;
DROP TABLE IF EXISTS Artist_Labels CASCADE;
DROP TABLE IF EXISTS Artists CASCADE;
DROP TABLE IF EXISTS Label_Admins CASCADE;
DROP TABLE IF EXISTS Resource_Shares CASCADE;
DROP TABLE IF EXISTS Role_Permissions CASCADE;
DROP TABLE IF EXISTS User_Roles CASCADE;
DROP TABLE IF EXISTS Follows CASCADE;
DROP TABLE IF EXISTS Labels CASCADE;
DROP TABLE IF EXISTS Permissions CASCADE;
DROP TABLE IF EXISTS Roles CASCADE;
DROP TABLE IF EXISTS Users CASCADE;


CREATE TABLE Users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    email VARCHAR(64) NOT NULL UNIQUE,
    password VARCHAR(64) NOT NULL,
    full_name VARCHAR(64) NOT NULL,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT is_valid_email CHECK (
        email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

CREATE TABLE Labels (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE Label_Admins (
    id BIGSERIAL PRIMARY KEY,
    label_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    FOREIGN KEY (label_id) REFERENCES Labels(id),
    FOREIGN KEY (user_id) REFERENCES Users(id),

    CONSTRAINT unique_user_admin UNIQUE (user_id)
);

CREATE TABLE Artists (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,

    FOREIGN KEY (user_id) REFERENCES Users(id)
);


CREATE TABLE Roles (
   id BIGSERIAL PRIMARY KEY,
   role_name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE User_Roles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,

    FOREIGN KEY (user_id) REFERENCES Users(id),
    FOREIGN KEY (role_id) REFERENCES Roles(id)
);



CREATE TABLE Permissions (
    id BIGSERIAL PRIMARY KEY,
    action VARCHAR(255) NOT NULL,
    resource_type VARCHAR(255) NOT NULL,
    scope VARCHAR(32) NOT NULL,

    CONSTRAINT scope_constraint CHECK ( scope in ('ANY','PUBLIC','SHARED','OWN')),
    CONSTRAINT resource_type_constraint CHECK ( resource_type in ('SONG','ALBUM','PLAYLIST')),
    CONSTRAINT action_constraint CHECK ( action in ('CREATE','EDIT','PLAY', 'VIEW','DELETE','SHARE','ADD_SONG','REMOVE_SONG'))
);

CREATE TABLE Role_Permissions (
    id BIGSERIAL PRIMARY KEY,
    permission_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,

    FOREIGN KEY (permission_id) REFERENCES Permissions(id),
    FOREIGN KEY (role_id) REFERENCES Roles(id),

    UNIQUE (role_id,permission_id)
);

CREATE TABLE Songs (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    visibility VARCHAR(64) NOT NULL,
    owner_artist_id BIGINT NOT NULL,
    published_by_artist_id INTEGER NULL,
    published_by_label_admin_id INTEGER NULL,
    genre VARCHAR(255) NULL,

    FOREIGN KEY (owner_artist_id) REFERENCES Artists(id),
    FOREIGN KEY (published_by_artist_id) REFERENCES Artists(id),
    FOREIGN KEY (published_by_label_admin_id) REFERENCES Label_Admins(id),

    CONSTRAINT visibility_constraint CHECK ( visibility in ('PUBLIC','PRIVATE','SHARED')),

    CHECK (
       (published_by_artist_id IS NOT NULL)::int +
       (published_by_label_admin_id IS NOT NULL)::int = 1
       ),
    CHECK (
       published_by_artist_id IS NULL OR published_by_artist_id = owner_artist_id
       )
);


CREATE TABLE Follows (
    id BIGSERIAL PRIMARY KEY,
    follower_user_id BIGINT NOT NULL,
    followed_user_id BIGINT NOT NULL,
    followed_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (follower_user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (followed_user_id) REFERENCES Users(id) ON DELETE CASCADE,

    CONSTRAINT no_self_follow CHECK ( follower_user_id<>followed_user_id ),

    UNIQUE (follower_user_id, followed_user_id)
);

CREATE TABLE Artist_Labels (
    id BIGSERIAL PRIMARY KEY,
    artist_id BIGINT NOT NULL,
    label_id BIGINT NOT NULL,
    active BOOLEAN NULL,
    start_date DATE NULL,
    end_date DATE NULL,

    FOREIGN KEY (artist_id) REFERENCES Artists(id),
    FOREIGN KEY (label_id) REFERENCES Labels(id)

);

CREATE TABLE Playlists (
    id BIGSERIAL PRIMARY KEY,
    visibility VARCHAR(255) NOT NULL,
    creator_user_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    playlist_name VARCHAR(255) NOT NULL,
    description VARCHAR(255) NULL,

    FOREIGN KEY (creator_user_id) REFERENCES Users(id),
    CONSTRAINT visibility_constraint CHECK ( visibility in ('PUBLIC','PRIVATE','SHARED'))
);

CREATE TABLE Saved_Playlists (
    id BIGSERIAL PRIMARY KEY,
    playlist_id BIGINT NOT NULL,
    saved_by BIGINT NOT NULL,
    saved_at TIMESTAMP NOT NULL DEFAULT now(),

    FOREIGN KEY (playlist_id) REFERENCES Playlists(id),
    FOREIGN KEY (saved_by) REFERENCES Users(id),

    UNIQUE (playlist_id, saved_by)
);


CREATE TABLE Albums (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255),
    visibility VARCHAR(255) NOT NULL,
    owner_artist_id BIGINT NOT NULL,
    published_by_artist_id INTEGER NULL,
    published_by_label_admin_id INTEGER NULL,

    FOREIGN KEY (owner_artist_id) REFERENCES Artists(id),
    FOREIGN KEY (published_by_artist_id) REFERENCES Artists(id),
    FOREIGN KEY (published_by_label_admin_id) REFERENCES Label_Admins(id),

    CONSTRAINT visibility_constraint CHECK ( visibility in ('PUBLIC','PRIVATE','SHARED')),
    CHECK (
        (published_by_artist_id IS NOT NULL)::int +
        (published_by_label_admin_id IS NOT NULL)::int = 1
    ),
    CHECK (
        published_by_artist_id IS NULL OR published_by_artist_id = owner_artist_id
    )

    -- TODO: treba da se dodade trigger za da se proveri deka dokolku pesnata e objavena od label, artist owner-ot e momentalno so toj label
);


CREATE TABLE Album_Tracks (
    id BIGSERIAL PRIMARY KEY,
    album_id BIGINT NOT NULL,
    song_id BIGINT NOT NULL,
    track_number INTEGER NOT NULL,

    FOREIGN KEY (album_id) REFERENCES Albums(id),
    FOREIGN KEY (song_id) REFERENCES Songs(id) ON DELETE CASCADE,

    UNIQUE (album_id, song_id),
    UNIQUE (album_id, track_number),

    CONSTRAINT track_number_positive CHECK ( track_number > 0 )
);

CREATE TABLE Playlist_Tracks (
    id BIGSERIAL PRIMARY KEY,
    song_id BIGINT NOT NULL,
    playlist_id BIGINT NOT NULL,
    added_at TIMESTAMP NOT NULL DEFAULT now(),

    FOREIGN KEY (song_id) REFERENCES Songs(id) ON DELETE CASCADE,
    FOREIGN KEY (playlist_id) REFERENCES Playlists(id),

    UNIQUE (playlist_id, song_id)
);

CREATE TABLE Song_Contents (
    id BIGSERIAL PRIMARY KEY,
    song_id BIGINT NOT NULL,
    content BYTEA NOT NULL UNIQUE,
    FOREIGN KEY (song_id) REFERENCES Songs(id) ON DELETE CASCADE
);

CREATE TABLE Song_Relationships (
    id BIGSERIAL PRIMARY KEY,
    source_song_id BIGINT NOT NULL,
    target_song_id BIGINT NOT NULL,
    relationship_type VARCHAR(255) NOT NULL, -- remix, cover
    FOREIGN KEY (source_song_id) REFERENCES Songs(id),
    FOREIGN KEY (target_song_id) REFERENCES Songs(id)
);

CREATE TABLE Song_Contributors (
    id BIGSERIAL PRIMARY KEY,
    song_id BIGINT NOT NULL,
    artist_id BIGINT NOT NULL,
    role VARCHAR(255) NOT NULL,
    credit_order INTEGER NOT NULL,

    FOREIGN KEY (song_id) REFERENCES Songs(id) ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES Artists(id),

    CONSTRAINT credit_order_positive CHECK ( credit_order > 0 )
);


CREATE TABLE Playback_Sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    song_id BIGINT NOT NULL,
    started_at TIMESTAMP NOT NULL,
    listened_ms INTEGER NOT NULL,
    last_position_ms INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES Users(id),
    FOREIGN KEY (song_id) REFERENCES Songs(id)
);


CREATE TABLE Song_Streams (
    id BIGSERIAL PRIMARY KEY,
    playback_session_id BIGINT NOT NULL,
    song_id BIGINT NOT NULL,
    streamed_at TIMESTAMP NOT NULL,
    user_id BIGINT NOT NULL,

    FOREIGN KEY (playback_session_id) REFERENCES Playback_Sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES Songs(id)
);


CREATE TABLE Reviews (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    song_id BIGINT NOT NULL,
    reviewed_at TIMESTAMP NOT NULL DEFAULT now(),
    grade INTEGER NOT NULL,
    comment VARCHAR(500) NULL,

    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES Songs(id) ON DELETE CASCADE,
    CONSTRAINT grade_valid CHECK ( grade BETWEEN 1 and 5)
);

CREATE TABLE Resource_Shares (
    id BIGSERIAL PRIMARY KEY,

    song_id BIGINT REFERENCES songs(id),
    album_id BIGINT REFERENCES albums(id),
    playlist_id BIGINT REFERENCES playlists(id),

    user_id BIGINT REFERENCES users(id),
    role_id BIGINT REFERENCES roles(id),

    permission_id BIGINT REFERENCES permissions(id),

    resource_type TEXT GENERATED ALWAYS AS (
        CASE
            WHEN song_id IS NOT NULL THEN 'SONG'
            WHEN album_id IS NOT NULL THEN 'ALBUM'
            WHEN playlist_id IS NOT NULL THEN 'PLAYLIST'
        END
    ) STORED,

    subject_type TEXT GENERATED ALWAYS AS (
        CASE
            WHEN user_id IS NOT NULL THEN 'USER'
            WHEN role_id IS NOT NULL THEN 'ROLE'
        END
    ) STORED,

    CHECK (
        (song_id IS NOT NULL)::int +
        (album_id IS NOT NULL)::int +
        (playlist_id IS NOT NULL)::int = 1
    ),

    CHECK (
        (user_id IS NOT NULL)::int +
        (role_id IS NOT NULL)::int = 1
    )
);
