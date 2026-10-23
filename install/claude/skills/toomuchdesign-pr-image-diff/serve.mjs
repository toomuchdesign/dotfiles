#!/usr/bin/env node
// Downloads every image a GitHub PR changes (merge base vs head) and serves a local diff viewer.
import { execFile, spawn } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { readFile, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';

const run = promisify(execFile);
const IMAGE_RE = /\.(png|jpe?g|gif|webp)$/i;
const CONCURRENCY = 6;

const args = process.argv.slice(2);
const noOpen = args.includes('--no-open');
const prUrl = args.find((arg) => !arg.startsWith('--'));
const match = prUrl?.match(/^https?:\/\/([^/]+)\/([^/]+)\/([^/]+)\/pull\/(\d+)/);
if (!match) {
  console.error('Usage: serve.mjs <github-pr-url> [--no-open]');
  process.exit(1);
}
const [, host, owner, repo, number] = match;
const repoPath = `repos/${owner}/${repo}`;

async function gh(apiArgs, encoding = 'utf8') {
  const { stdout } = await run('gh', ['api', '--hostname', host, ...apiArgs], {
    encoding,
    maxBuffer: 1 << 28,
  });
  return stdout;
}

const pr = JSON.parse(await gh([`${repoPath}/pulls/${number}`]));
const mergeBase = (
  await gh([`${repoPath}/compare/${pr.base.sha}...${pr.head.sha}`, '--jq', '.merge_base_commit.sha'])
).trim();
const changed = (
  await gh(['--paginate', `${repoPath}/pulls/${number}/files`, '--jq', '.[] | {filename, previous_filename, status}'])
)
  .split('\n')
  .filter(Boolean)
  .map((line) => JSON.parse(line))
  .filter((file) => IMAGE_RE.test(file.filename));

if (changed.length === 0) {
  console.error(`PR #${number} changes no images.`);
  process.exit(1);
}

const dir = mkdtempSync(path.join(tmpdir(), `pr-image-diff-${number}-`));
process.on('exit', () => rmSync(dir, { recursive: true, force: true }));
process.on('SIGINT', () => process.exit(0));
process.on('SIGTERM', () => process.exit(0));

const files = changed.map((file, id) => ({
  id,
  path: file.filename,
  previousPath: file.previous_filename,
  status: file.status,
  hasBase: file.status !== 'added',
  hasHead: file.status !== 'removed',
}));

async function download(file, side) {
  const filePath = side === 'base' ? (file.previousPath ?? file.path) : file.path;
  const ref = side === 'base' ? mergeBase : pr.head.sha;
  const encoded = filePath.split('/').map(encodeURIComponent).join('/');
  const data = await gh(['-H', 'Accept: application/vnd.github.raw', `${repoPath}/contents/${encoded}?ref=${ref}`], 'buffer');
  await writeFile(path.join(dir, `${file.id}-${side}`), data);
}

const jobs = files.flatMap((file) => [
  ...(file.hasBase ? [() => download(file, 'base')] : []),
  ...(file.hasHead ? [() => download(file, 'head')] : []),
]);
let done = 0;
await Promise.all(
  Array.from({ length: CONCURRENCY }, async () => {
    while (jobs.length) {
      await jobs.shift()();
      process.stderr.write(`\rDownloaded ${++done} images`);
    }
  }),
);
process.stderr.write('\n');

const manifest = JSON.stringify({
  title: pr.title,
  url: pr.html_url,
  number: pr.number,
  base: mergeBase,
  head: pr.head.sha,
  files,
});
const viewer = await readFile(path.join(path.dirname(fileURLToPath(import.meta.url)), 'viewer.html'));
const MIME = { png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', gif: 'image/gif', webp: 'image/webp' };

const server = createServer(async (req, res) => {
  const { pathname } = new URL(req.url, 'http://localhost');
  const image = pathname.match(/^\/img\/(\d+)\/(base|head)$/);
  if (pathname === '/') {
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }).end(viewer);
  } else if (pathname === '/manifest.json') {
    res.writeHead(200, { 'content-type': 'application/json' }).end(manifest);
  } else if (image && files[image[1]]) {
    const ext = files[image[1]].path.split('.').pop().toLowerCase();
    try {
      const data = await readFile(path.join(dir, `${image[1]}-${image[2]}`));
      res.writeHead(200, { 'content-type': MIME[ext], 'cache-control': 'max-age=3600' }).end(data);
    } catch {
      res.writeHead(404).end();
    }
  } else if (pathname === '/close' && req.method === 'POST') {
    res.writeHead(204).end();
    server.close();
    process.exit(0);
  } else {
    res.writeHead(404).end();
  }
});

server.listen(Number(process.env.PORT) || 0, '127.0.0.1', () => {
  const url = `http://127.0.0.1:${server.address().port}/`;
  console.log(`PR #${number}: ${files.length} images. Viewer: ${url}`);
  if (!noOpen) spawn(process.platform === 'darwin' ? 'open' : 'xdg-open', [url], { stdio: 'ignore', detached: true }).unref();
});
