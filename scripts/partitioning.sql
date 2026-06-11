-- напредна тема 1: партиционирање на song_streams по streamed_at

-- 1. create schema for archived partitions

-- schema for storing detached partitions, ideally this would be 
-- moved to a cheaper/slower storage in a real world scenario
CREATE SCHEMA IF NOT EXISTS archive;


-- 2. convert song_streams to a partitioned table
BEGIN;

-- 2.1 first we detach the sequence so that we could later attach it to the new table,
-- otherwise drop table would remove it.
ALTER SEQUENCE song_streams_id_seq OWNED BY NONE;

-- 2.2a  we don't drop the table yet because we need it for checks later. we just rename it
ALTER TABLE song_streams RENAME TO song_streams_old;

-- 2.2b free up the index names so they could be used by the new relation
ALTER INDEX song_streams_pkey                     RENAME TO song_streams_old_pkey;
ALTER INDEX idx_song_streams_streamed_at_song_id  RENAME TO song_streams_old_streamed_at_song_id;
ALTER INDEX idx_song_streams_user_id              RENAME TO song_streams_old_user_id;


-- 2.3  create the new partitioned parent table. same columns but now with a composite PK that
-- includes the partition key (required by postgres); also attach the existing sequence from the old table

CREATE TABLE song_streams (
    id                  bigint                      NOT NULL DEFAULT nextval('song_streams_id_seq'),
    playback_session_id bigint                      NOT NULL,
    song_id             bigint                      NOT NULL,
    streamed_at         timestamp without time zone NOT NULL,
    user_id             bigint                      NOT NULL,

    PRIMARY KEY (id, streamed_at),

    FOREIGN KEY (playback_session_id) REFERENCES playback_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id)             REFERENCES songs(id)
) PARTITION BY RANGE (streamed_at);

-- 2.4  re-attach the sequence
ALTER SEQUENCE song_streams_id_seq OWNED BY song_streams.id;

-- 2.5  we recreate indexes on the parent, postgres automatically creates and manages
-- the indexes for each partition
CREATE INDEX idx_song_streams_streamed_at_song_id ON song_streams (streamed_at, song_id);
CREATE INDEX idx_song_streams_user_id             ON song_streams (user_id);

-- 2.6  create initial partitions for the existing data and a couple of months ahead.
-- in the future this will be handled automatically. this is just used for the initial bootstrap
-- we create partitions spanning 2025-11 to 2026-07
CREATE TABLE song_streams_y2025m11 PARTITION OF song_streams FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE song_streams_y2025m12 PARTITION OF song_streams FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE song_streams_y2026m01 PARTITION OF song_streams FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE song_streams_y2026m02 PARTITION OF song_streams FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE song_streams_y2026m03 PARTITION OF song_streams FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE song_streams_y2026m04 PARTITION OF song_streams FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE song_streams_y2026m05 PARTITION OF song_streams FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE song_streams_y2026m06 PARTITION OF song_streams FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE song_streams_y2026m07 PARTITION OF song_streams FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

-- default partition for handling rows with a missing partition
CREATE TABLE song_streams_default PARTITION OF song_streams DEFAULT;

-- 2.7  migrate the data. the insert implicitly routes to the right partition
INSERT INTO song_streams (id, playback_session_id, song_id, streamed_at, user_id)
SELECT id, playback_session_id, song_id, streamed_at, user_id
FROM song_streams_old;

-- 2.8  update the sequence
SELECT setval('song_streams_id_seq', (SELECT max(id) FROM song_streams));

-- 2.9  checks to assure that the tables are fully synced
-- SELECT count(*) FROM song_streams;
-- SELECT count(*) FROM song_streams_old;

COMMIT;

-- 2.10 drop table (only after checking that dependent views/matviews have been set against the new table)
-- DROP TABLE song_streams_old;

-- 2.11 Refresh planner stats on the new structure.
ANALYZE song_streams;



-- 3. function for creating current + future monthly partitions
-- worth noting that this function is idempotent so it is safe to run it multiple times per month
CREATE OR REPLACE FUNCTION create_song_streams_partitions(months_ahead integer DEFAULT 2)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    first_month date := date_trunc('month', current_date)::date;
    m           date;
    part_name   text;
    from_ts     timestamp;
    to_ts       timestamp;
BEGIN
    FOR i IN 0..months_ahead LOOP
        m         := (first_month + (i || ' months')::interval)::date;
        part_name := format('song_streams_y%sm%s', to_char(m, 'YYYY'), to_char(m, 'MM'));
        from_ts   := m;
        to_ts     := (m + interval '1 month');

        IF NOT EXISTS (
            SELECT 1 FROM pg_class WHERE relname = part_name AND relkind = 'r'
        ) THEN
            EXECUTE format(
                'CREATE TABLE %I PARTITION OF song_streams FOR VALUES FROM (%L) TO (%L)',
                part_name, from_ts, to_ts
            );
            RAISE NOTICE 'Created partition % (% .. %)', part_name, from_ts, to_ts;
        END IF;
    END LOOP;
END;
$$;


-- 4. function for archiving old partitions
-- retention_months = how many months we want to keep. default is 12 (1 year)

CREATE OR REPLACE FUNCTION archive_song_streams_partitions(retention_months integer DEFAULT 12)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    cutoff_month date := (date_trunc('month', current_date)
                          - (retention_months || ' months')::interval)::date;
    r            record;
    yr          int;
    mo          int;
    part_month  date;
    archived_name text;
BEGIN
    -- freeze counts for every closed month before we start detaching anything
    PERFORM seal_closed_song_streams_months();

    FOR r IN
        SELECT c.relname
        FROM pg_inherits i
        JOIN pg_class c ON c.oid = i.inhrelid
        JOIN pg_class p ON p.oid = i.inhparent
        WHERE p.relname = 'song_streams'
          AND c.relname ~ '^song_streams_y\d{4}m\d{2}$'   -- skip the default partition
    LOOP
        yr := substring(r.relname from 'y(\d{4})m')::int;
        mo := substring(r.relname from 'm(\d{2})$')::int;
        part_month := make_date(yr, mo, 1);

        IF part_month < cutoff_month THEN
            archived_name := r.relname || '_archived';

            -- 1. detach from the live table -> becomes a standalone table.
            EXECUTE format('ALTER TABLE song_streams DETACH PARTITION %I', r.relname);

            -- 2. move it into the archive schema and tag the name.
            EXECUTE format('ALTER TABLE %I SET SCHEMA archive', r.relname);
            EXECUTE format('ALTER TABLE archive.%I RENAME TO %I', r.relname, archived_name);

            RAISE NOTICE 'archived % -> archive.%', r.relname, archived_name;
        END IF;
    END LOOP;

    -- keep the full-history view in sync with the set of archived partitions (defined later in section 6)
    PERFORM rebuild_song_streams_all_view();
END;
$$;


-- 5. scheduling jobs using pg_cron

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- create upcoming partitions: runs daily at 02:00. daily (not monthly) so a
-- single missed day never leaves us without next month's partition.
SELECT cron.schedule(
    'song_streams_create_partitions',
    '0 2 * * *',
    $$SELECT create_song_streams_partitions(2)$$
);

-- archive old partitions: run on the 2nd of each month at 03:00.
SELECT cron.schedule(
    'song_streams_archive_partitions',
    '0 3 2 * *',
    $$SELECT archive_song_streams_partitions(12)$$
);

-- 6. function for dynamically creating a view that unions the existing song streams 
-- with all archived partitions
CREATE OR REPLACE FUNCTION rebuild_song_streams_all_view()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    cols   constant text := 'id, playback_session_id, song_id, streamed_at, user_id';
    sql    text;
    r      record;
BEGIN
    -- start from live table
    sql := format('SELECT %s FROM song_streams', cols);

    -- append one UNION ALL branch per archived partition, oldest first.
    FOR r IN
        SELECT n.nspname, c.relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'archive'
          AND c.relkind = 'r'
          AND c.relname ~ '^song_streams_y\d{4}m\d{2}_archived$'
        ORDER BY c.relname
    LOOP
        sql := sql || format(
            E'\n    UNION ALL\n    SELECT %s FROM %I.%I',
            cols, r.nspname, r.relname
        );
    END LOOP;

    EXECUTE format('CREATE OR REPLACE VIEW song_streams_all AS %s', sql);
    RAISE NOTICE 'Rebuilt song_streams_all view';
END;
$$;

-- SELECT rebuild_song_streams_all_view();