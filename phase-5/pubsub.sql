-- напредна тема 2: pub/sub преку Postgres LISTEN/NOTIFY
-- испраќаме нотификација на персонален канал кога корисник добива нов следбеник


-- тригер функција: при INSERT во follows се прави JSON payload
-- со податоци за follower-от (преку join со users) и испраќа на каналот
-- follows_user_<followed_user_id>

CREATE OR REPLACE FUNCTION trg_notify_new_follower()
    RETURNS TRIGGER AS $$
DECLARE
    v_channel TEXT;
    v_payload JSON;
BEGIN
    v_channel := 'follows_user_' || NEW.followed_user_id;

    SELECT json_build_object(
        'follower_id',        u.id,
        'follower_username',  u.username,
        'follower_full_name', u.full_name,
        'followed_id',        NEW.followed_user_id,
        'followed_at',        NEW.followed_at
    )
    INTO v_payload
    FROM Users u
    WHERE u.id = NEW.follower_user_id;

    PERFORM pg_notify(v_channel, v_payload::text);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS notify_new_follower ON follows;

CREATE TRIGGER notify_new_follower
    AFTER INSERT ON follows
    FOR EACH ROW
EXECUTE FUNCTION trg_notify_new_follower();
