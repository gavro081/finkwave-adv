-- напредна тема 1: партиционирање на song_streams по streamed_at

-- 1. pravime nova shema za arhiviranite particii

-- idealno ova bi bilo cuvano vo nekoj poevtin storage bidejki sakame da gi cuvame podatocite, 
-- no nema cesto da gi pristapuvame
CREATE SCHEMA IF NOT EXISTS archive;


-- 2. transakcija za migriranje na song_streams vo particionirana tabela
BEGIN;


-- 2.1 prvo pravime detach na sekvencata za posle da mozeme da ja prikacime kon novata tabela,
-- inaku drop table bi ja izbrisala
ALTER SEQUENCE song_streams_id_seq OWNED BY NONE;

-- 2.2a  se uste ne ja drop-nuvame tabelata bidejki ke ni treba za proverka na kraj. samo ja preimenuvame
ALTER TABLE song_streams RENAME TO song_streams_old;

-- 2.2b gi preimenuvame indeksite bidejki ovie iminja za indeksite ke ni trebaat za indeksite na novata relacija
ALTER INDEX song_streams_pkey                     RENAME TO song_streams_old_pkey;
ALTER INDEX idx_song_streams_streamed_at_song_id  RENAME TO song_streams_old_streamed_at_song_id;
ALTER INDEX idx_song_streams_user_id              RENAME TO song_streams_old_user_id;



-- 2.3  pravime nova particionirana parent tabela. istite koloni no so slozen PK koj sto go sodrzi i
-- particioniot kluc (streamed_at) - ova e requirement od samiot postgres
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

-- 2.4  ja prikacuvame sekvencata od prethodno
ALTER SEQUENCE song_streams_id_seq OWNED BY song_streams.id;

-- 2.5  gi rekreirame indeksite na parent-ot
-- postgres avtomatski ke gi kreira i menadzira indeksite za site particii
CREATE INDEX idx_song_streams_streamed_at_song_id ON song_streams (streamed_at, song_id);
CREATE INDEX idx_song_streams_user_id             ON song_streams (user_id);

-- 2.6  gi kreirame inicijalnite particii za postoeckite podatoci i nekolku meseci unapred.
-- vo idnina particiite ke bidat kreirani avtomatski, ova se koristi samo za inicijalniot bootstrap
-- kreirame particii od 2025-11 do 2026-07
CREATE TABLE song_streams_y2025m11 PARTITION OF song_streams FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE song_streams_y2025m12 PARTITION OF song_streams FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE song_streams_y2026m01 PARTITION OF song_streams FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE song_streams_y2026m02 PARTITION OF song_streams FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE song_streams_y2026m03 PARTITION OF song_streams FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE song_streams_y2026m04 PARTITION OF song_streams FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE song_streams_y2026m05 PARTITION OF song_streams FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE song_streams_y2026m06 PARTITION OF song_streams FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE song_streams_y2026m07 PARTITION OF song_streams FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

-- default particija za zapisi koj nemaat soodvetna particija
CREATE TABLE song_streams_default PARTITION OF song_streams DEFAULT;

-- 2.7  migracija na podatocite. insertot implicitno gi rutira site zapisi kon tocnata particija
INSERT INTO song_streams (id, playback_session_id, song_id, streamed_at, user_id)
SELECT id, playback_session_id, song_id, streamed_at, user_id
FROM song_streams_old;

-- 2.8  update na sekvencata
SELECT setval('song_streams_id_seq', (SELECT max(id) FROM song_streams));

-- 2.9  proverki za da vidime deka site podatoci se preneseni
-- SELECT count(*) FROM song_streams;
-- SELECT count(*) FROM song_streams_old;

COMMIT;

-- 2.10 drop na starata tabela (samo otkako sme utvrdile deka zavisnite views/matviews se postaveni kon novata tabela)
-- DROP TABLE song_streams_old;

-- 2.11 refresh na statistikite na planner-ot
ANALYZE song_streams;



-- 3. funkcija za kreiranje segasna + idni particii
-- funkcijata e idempotentna - moze da se izvrsuva poveke pati vo mesecot bez neposakuvani side effects
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


-- 4. funkcija za arhiviranje stari particii
-- retention_months = kolku meseci sakame da cuvame. default vrednost e 12 (1 godina)

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
    -- zamrznuvame brojaci za sekoj zatvoren mesec pred da pocneme
    PERFORM seal_closed_song_streams_months();

    FOR r IN
        SELECT c.relname
        FROM pg_inherits i
        JOIN pg_class c ON c.oid = i.inhrelid
        JOIN pg_class p ON p.oid = i.inhparent
        WHERE p.relname = 'song_streams'
          AND c.relname ~ '^song_streams_y\d{4}m\d{2}$' -- isklucuva default particija
    LOOP
        yr := substring(r.relname from 'y(\d{4})m')::int;
        mo := substring(r.relname from 'm(\d{2})$')::int;
        part_month := make_date(yr, mo, 1);

        IF part_month < cutoff_month THEN
            archived_name := r.relname || '_archived';

            -- 1. otstranuvame particija od parent tabelata -> stanuva standalone tabela.
            EXECUTE format('ALTER TABLE song_streams DETACH PARTITION %I', r.relname);

            -- 2. ja pomestuvame vo archive shemata i ja preimenuvame soodvetno
            EXECUTE format('ALTER TABLE %I SET SCHEMA archive', r.relname);
            EXECUTE format('ALTER TABLE archive.%I RENAME TO %I', r.relname, archived_name);

            RAISE NOTICE 'archived % -> archive.%', r.relname, archived_name;
        END IF;
    END LOOP;

    -- sinhronizacija na full-history view so novite arhivirani particii (sekcija 6)
    PERFORM rebuild_song_streams_all_view();
END;
$$;


-- 5. job scheduling so pg_cron

CREATE EXTENSION IF NOT EXISTS pg_cron;


-- sozdava novi particii za mesecite sto sledat: se izvrsuva sekoj den vo 02:00. 
-- dnevno, namesto mesecno za propusten den da ne znaci deka nema da se sozdade novata particija
SELECT cron.schedule(
    'song_streams_create_partitions',
    '0 2 * * *',
    $$SELECT create_song_streams_partitions(2)$$
);

-- arhiviranje stari particii: se izvrsuva na vtoriot den od sekoj mesec vo 03:00.
SELECT cron.schedule(
    'song_streams_archive_partitions',
    '0 3 2 * *',
    $$SELECT archive_song_streams_partitions(12)$$
);


-- 6. funkcija za dinamicko kreiranje na view sto gi spojuva postoeckite song streams
-- so site arhivirani particii
CREATE OR REPLACE FUNCTION rebuild_song_streams_all_view()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    cols   constant text := 'id, playback_session_id, song_id, streamed_at, user_id';
    sql    text;
    r      record;
BEGIN
    -- zapocni od postoeckata ("ziva") tabela
    sql := format('SELECT %s FROM song_streams', cols);

    -- dodavaj po edno UNION ALL za sekoja arhivirana particija, pocnuvajki od najstarata
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