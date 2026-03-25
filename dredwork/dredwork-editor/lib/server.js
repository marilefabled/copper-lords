/**
 * dredwork-editor — HTTP Server
 * Config-driven Lua text editor server.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { parseFile } = require('./lua-parser');
const { buildRegistry } = require('./file-registry');
const { applyEdit } = require('./edit-engine');
const { addEntry } = require('./add-engine');

const MIME = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
};

function sendJSON(res, data, status = 200) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try { resolve(JSON.parse(body)); }
      catch (e) { reject(e); }
    });
    req.on('error', reject);
  });
}

/**
 * Start the editor server.
 * @param {object} config Loaded config object
 * @param {string} projectRoot Absolute path to the project
 */
function startServer(config, projectRoot) {
  const port = config.port || 3333;
  const registry = buildRegistry(config.files, projectRoot);

  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, `http://localhost:${port}`);
    const pathname = url.pathname;

    // ── API Routes ──

    // GET /api/config — client-side config (name, colors, welcome, reference, modals)
    if (pathname === '/api/config' && req.method === 'GET') {
      return sendJSON(res, {
        name: config.name,
        subtitle: config.subtitle,
        colorWords: config.colorWords || {},
        welcome: config.welcome,
        reference: config.reference || {},
        theme: config.theme || null,
      });
    }

    // GET /api/files — file registry grouped by category
    if (pathname === '/api/files' && req.method === 'GET') {
      const categories = {};
      for (const f of registry) {
        if (!categories[f.category]) categories[f.category] = [];
        categories[f.category].push({
          path: f.path,
          label: f.label,
          type: f.type,
          addable: f.addable,
        });
      }
      return sendJSON(res, { categories });
    }

    // POST /api/parse — parse a Lua file into editable groups
    if (pathname === '/api/parse' && req.method === 'POST') {
      try {
        const { filePath, fileType } = await readBody(req);
        const absPath = path.join(projectRoot, filePath);
        if (!fs.existsSync(absPath)) return sendJSON(res, { error: 'File not found' }, 404);

        const source = fs.readFileSync(absPath, 'utf8');
        const groups = parseFile(source, filePath, fileType);
        return sendJSON(res, { groups, lineCount: source.split('\n').length });
      } catch (e) {
        return sendJSON(res, { error: e.message }, 500);
      }
    }

    // POST /api/edit — apply a text edit
    if (pathname === '/api/edit' && req.method === 'POST') {
      try {
        const { file, start, end, raw, newValue } = await readBody(req);
        const result = applyEdit(projectRoot, file, start, end, raw, newValue);
        return sendJSON(res, result);
      } catch (e) {
        return sendJSON(res, { error: e.message }, 500);
      }
    }

    // POST /api/add — add a new entry
    if (pathname === '/api/add' && req.method === 'POST') {
      try {
        const { filePath, fileType, data } = await readBody(req);
        const result = addEntry(projectRoot, filePath, fileType, data, config.templates || {});
        return sendJSON(res, result);
      } catch (e) {
        return sendJSON(res, { error: e.message }, 500);
      }
    }

    // GET /api/reference — reference data
    if (pathname === '/api/reference' && req.method === 'GET') {
      return sendJSON(res, config.reference || {});
    }

    // POST /api/raw — raw file source
    if (pathname === '/api/raw' && req.method === 'POST') {
      try {
        const { filePath } = await readBody(req);
        const absPath = path.join(projectRoot, filePath);
        const source = fs.readFileSync(absPath, 'utf8');
        return sendJSON(res, { source });
      } catch (e) {
        return sendJSON(res, { error: e.message }, 500);
      }
    }

    // ── Static Files ──
    let filePath = pathname === '/' ? '/index.html' : pathname;
    const publicDir = path.join(__dirname, '..', 'public');
    const fullPath = path.join(publicDir, filePath);

    if (fs.existsSync(fullPath) && fs.statSync(fullPath).isFile()) {
      const ext = path.extname(fullPath);
      res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
      return fs.createReadStream(fullPath).pipe(res);
    }

    res.writeHead(404);
    res.end('Not found');
  });

  server.listen(port, () => {
    const nameUpper = (config.name || 'PROJECT').toUpperCase();
    console.log(`\n  \u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557`);
    console.log(`  \u2551  ${nameUpper} ${(config.subtitle || 'TEXT EDITOR').toUpperCase()}${' '.repeat(Math.max(0, 38 - nameUpper.length - (config.subtitle || 'TEXT EDITOR').length))}\u2551`);
    console.log(`  \u2551  http://localhost:${port}${' '.repeat(Math.max(0, 38 - String(port).length - 17))}\u2551`);
    console.log(`  \u2551${' '.repeat(42)}\u2551`);
    console.log(`  \u2551  Project: ${path.basename(projectRoot).padEnd(30)}\u2551`);
    console.log(`  \u2551  Files:   ${String(registry.length).padEnd(30)}\u2551`);
    console.log(`  \u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\n`);
  });

  return server;
}

module.exports = { startServer };
