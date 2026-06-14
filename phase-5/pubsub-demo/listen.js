import pg from 'pg';

const { Client } = pg;

function parseUserId() {
    const args = process.argv.slice(2);
    const idx = args.indexOf('--user');
    const raw = idx >= 0 ? args[idx + 1] : process.env.FOLLOWED_USER_ID;
    const id = Number.parseInt(raw, 10);
    if (!Number.isInteger(id) || id <= 0) {
        console.error('usage: node listen.js --user <positive integer>');
        process.exit(1);
    }
    return id;
}

const userId = parseUserId();
const connectionString =
    process.env.DATABASE_URL || 'postgres://Filip@localhost/finkwave_test';

const client = new Client({ connectionString });

const channel = `follows_user_${userId}`;
const quotedChannel = `"${channel.replace(/"/g, '""')}"`;

client.on('notification', (msg) => {
    if (msg.channel !== channel) return;
    try {
        const p = JSON.parse(msg.payload);
        const name = p.follower_full_name || p.follower_username;
        console.log(
            `[${p.followed_at}] ${name} (@${p.follower_username}) followed you`
        );
    } catch (err) {
        console.error('failed to parse payload:', msg.payload, err);
    }
});

client.on('error', (err) => {
    console.error('pg client error:', err);
    process.exit(1);
});

async function main() {
    await client.connect();
    await client.query(`LISTEN ${quotedChannel}`);
    console.log(
        `listening on ${channel} as user ${userId} — waiting for follows...`
    );
}

async function shutdown() {
    try { await client.query(`UNLISTEN ${quotedChannel}`); } catch {}
    try { await client.end(); } catch {}
    process.exit(0);
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

main().catch((err) => { console.error(err); process.exit(1); });
