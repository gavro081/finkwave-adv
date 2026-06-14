import { readFile } from 'node:fs/promises';
import http from 'node:http';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const { Pool } = pg;

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 3000;
const connectionString =
    process.env.DATABASE_URL || 'postgres://Filip@localhost/finkwave_test';

const pool = new Pool({ connectionString });

// klk bajti max da vratime ako browser-ot pobara se do kraj
const MAX_CHUNK = 1 << 20; // 1 MiB

const DEMO_USER_ID = Number(process.env.DEMO_USER_ID || 1);

function readJson(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', (c) => {
            body += c;
            if (body.length > 1e6) reject(new Error('body too large'));
        });
        req.on('end', () => {
            try {
                resolve(body ? JSON.parse(body) : {});
            } catch (e) {
                reject(e);
            }
        });
        req.on('error', reject);
    });
}


// prv song id so song content
async function defaultSongId() {
    const { rows } = await pool.query(
        `SELECT s.id, s.title
         FROM song_contents sc
         JOIN songs s ON s.id = sc.song_id
         ORDER BY sc.id
         LIMIT 1`
    );
    return rows[0] || null;
}

function parseRange(header, size) {
    // format: "bytes=START-END"
    if (!header) return null;
    const m = /^bytes=(\d*)-(\d*)$/.exec(header.trim());
    if (!m) return null;

    let start = m[1] === '' ? null : Number(m[1]);
    let end = m[2] === '' ? null : Number(m[2]);

    if (start === null && end === null) return null;
    if (start === null) {
        start = Math.max(0, size - end);
        end = size - 1;
    } else if (end === null) {
        end = size - 1;
    }

    if (start > end || start >= size) return { invalid: true };
    end = Math.min(end, size - 1);
    return { start, end };
}

async function serveStream(req, res, songId) {
    const size = (await pool.query('SELECT song_content_size($1) AS size', [songId]))
        .rows[0]?.size;

    if (size == null) {
        res.writeHead(404).end('song content not found');
        return;
    }
    const total = Number(size);

    const range = parseRange(req.headers.range, total);

    if (range?.invalid) {
        res.writeHead(416, { 'Content-Range': `bytes */${total}` }).end();
        return;
    }

    
    // ako nema Range, prakame prviot segment i deka poddrzuvame range (Accept-Ranges)
    // browser-ot ke prodolzi sam so Range baranja
    const start = range ? range.start : 0;
    const end = range
        ? Math.min(range.end, start + MAX_CHUNK - 1)
        : Math.min(total - 1, MAX_CHUNK - 1);
    const length = end - start + 1;

    const chunk = (
        await pool.query('SELECT song_content_chunk($1, $2, $3) AS data', [
            songId,
            start,
            length,
        ])
    ).rows[0]?.data;

    res.writeHead(206, {
        'Content-Type': 'audio/mpeg',
        'Accept-Ranges': 'bytes',
        'Content-Range': `bytes ${start}-${end}/${total}`,
        'Content-Length': chunk.length,
        'Cache-Control': 'no-store',
    });
    res.end(chunk);
}

const server = http.createServer(async (req, res) => {
    try {
        const url = new URL(req.url, `http://${req.headers.host}`);

        // index page
        if (req.method === 'GET' && url.pathname === '/') {
            const html = await readFile(join(__dirname, 'public', 'index.html'));
            res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }).end(html);
            return;
        }

        // get song to play
        if (req.method === 'GET' && url.pathname === '/api/song') {
            const song = await defaultSongId();
            if (!song) {
                res.writeHead(404, { 'Content-Type': 'application/json' })
                    .end(JSON.stringify({ error: 'no song with content found' }));
                return;
            }
            res.writeHead(200, { 'Content-Type': 'application/json' })
                .end(JSON.stringify(song));
            return;
        }

        // start session
        if (req.method === 'POST' && url.pathname === '/api/play') {
            const { songId } = await readJson(req);
            const { rows } = await pool.query(
                'SELECT start_playback_session($1, $2) AS id',
                [DEMO_USER_ID, Number(songId)]
            );
            res.writeHead(200, { 'Content-Type': 'application/json' })
                .end(JSON.stringify({ sessionId: rows[0].id }));
            return;
        }

        // send heartbeat
        if (req.method === 'POST' && url.pathname === '/api/progress') {
            const { sessionId, listenedMs, positionMs } = await readJson(req);
            await pool.query('SELECT update_playback_progress($1, $2, $3)', [
                Number(sessionId),
                Math.trunc(listenedMs),
                Math.trunc(positionMs),
            ]);
            res.writeHead(204).end();
            return;
        }

        // the stream itself
        const streamMatch = /^\/stream\/(\d+)$/.exec(url.pathname);
        if (req.method === 'GET' && streamMatch) {
            await serveStream(req, res, Number(streamMatch[1]));
            return;
        }

        res.writeHead(404).end('not found');
    } catch (err) {
        console.error(err);
        if (!res.headersSent) res.writeHead(500);
        res.end('server error');
    }
});

server.listen(PORT, () => {
    console.log(`streaming demo on http://localhost:${PORT}`);
});

function shutdown() {
    server.close();
    pool.end().finally(() => process.exit(0));
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
