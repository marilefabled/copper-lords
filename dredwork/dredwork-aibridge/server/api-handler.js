/**
 * dredwork-aibridge: API Handler
 * Server-side module that wires decode → generate → store into an HTTP handler.
 *
 * HOOKS:
 *   onReceive(rawPayload)            Optional. Called after successful decode. Return false to reject.
 *   onGenerated(result, rawPayload)  Optional. Called after AI generation completes.
 *   store(record)                    Optional. Persist the result. Receives { id, payload, raw, result, timestamp }.
 *   generateId()                     Optional. Custom ID generator. Default: 8-char random hex.
 *   rateLimit(ip)                    Optional. Return true to allow, false to reject.
 *
 * Works with:
 *   - Node.js http module
 *   - Express/Koa (wrap with adapter)
 *   - Cloudflare Workers (use handleRequest directly)
 */

const crypto = require('crypto');

/**
 * Create an API handler.
 * @param {object} opts
 * @param {object} opts.decoder Decoder from payload-decoder.js (createDecoder result)
 * @param {object} opts.generator Generator from ai-generator.js (createGenerator result)
 * @param {function} opts.onReceive (rawPayload) -> boolean|void. Optional.
 * @param {function} opts.onGenerated (result, rawPayload) -> void. Optional.
 * @param {function} opts.store (record) -> Promise<void>. Optional.
 * @param {function} opts.generateId () -> string. Optional.
 * @param {function} opts.rateLimit (ip) -> boolean. Optional.
 * @param {number} opts.maxBodySize Max request body in bytes. Default: 512KB.
 * @returns {object} Handler with handleRequest() and createNodeHandler() methods
 */
function createHandler(opts = {}) {
  const {
    decoder,
    generator,
    onReceive,
    onGenerated,
    store,
    generateId,
    rateLimit,
    maxBodySize = 512 * 1024,
  } = opts;

  if (!decoder) throw new Error('decoder is required');
  if (!generator) throw new Error('generator is required');

  function makeId() {
    if (generateId) return generateId();
    return crypto.randomBytes(4).toString('hex');
  }

  /**
   * Handle a submit request.
   * @param {object} params
   * @param {string} params.body Request body (string)
   * @param {string} params.ip Client IP
   * @returns {Promise<{ status: number, body: object }>}
   */
  async function handleRequest({ body, ip }) {
    // Rate limit
    if (rateLimit) {
      const allowed = rateLimit(ip);
      if (!allowed) {
        return { status: 429, body: { success: false, error: 'Rate limit exceeded' } };
      }
    }

    // Size check
    if (body && body.length > maxBodySize) {
      return { status: 413, body: { success: false, error: 'Payload too large' } };
    }

    // Parse body
    let parsed;
    try {
      parsed = JSON.parse(body);
    } catch (e) {
      return { status: 400, body: { success: false, error: 'Invalid JSON' } };
    }

    // Determine input: look for a 'code' field (wire format) or use entire body
    const input = parsed.code || JSON.stringify(parsed);

    // Decode
    const { payload, raw, error } = decoder.decode(input);
    if (error || !payload) {
      return { status: 400, body: { success: false, error: error || 'Decode failed' } };
    }

    // onReceive hook
    if (onReceive) {
      try {
        const ok = onReceive(raw || payload);
        if (ok === false) {
          return { status: 400, body: { success: false, error: 'Rejected by onReceive hook' } };
        }
      } catch (e) {
        return { status: 400, body: { success: false, error: 'Receive hook error: ' + e.message } };
      }
    }

    // Generate ID
    const id = makeId();
    const timestamp = new Date().toISOString();

    // Store initial record
    if (store) {
      try {
        await store({ id, payload, raw, result: null, status: 'received', timestamp });
      } catch (e) {
        console.error('[dredwork-aibridge] Store failed:', e.message);
      }
    }

    // Generate
    const aiInput = raw || payload;
    const result = await generator.generate(aiInput);

    // onGenerated hook
    if (onGenerated) {
      try {
        onGenerated(result, raw || payload);
      } catch (e) {
        console.error('[dredwork-aibridge] onGenerated hook failed:', e.message);
      }
    }

    // Store result
    if (store) {
      try {
        await store({
          id,
          payload,
          raw,
          result,
          status: result.success ? 'complete' : 'error',
          timestamp,
        });
      } catch (e) {
        console.error('[dredwork-aibridge] Store update failed:', e.message);
      }
    }

    if (!result.success) {
      return { status: 500, body: { success: false, error: result.error, id } };
    }

    return {
      status: 200,
      body: {
        success: true,
        id,
        structured: result.structured || null,
        prose: result.prose || null,
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
      },
    };
  }

  /**
   * Create a Node.js http-compatible request handler.
   * Use with: http.createServer(handler.createNodeHandler())
   * @param {string} path URL path to handle (default: "/api/generate")
   * @returns {function} (req, res) handler
   */
  function createNodeHandler(path = '/api/generate') {
    return async (req, res) => {
      const url = new URL(req.url, `http://localhost`);
      if (url.pathname !== path || req.method !== 'POST') {
        return false; // Not handled
      }

      // Read body
      const chunks = [];
      for await (const chunk of req) {
        chunks.push(chunk);
      }
      const body = Buffer.concat(chunks).toString('utf8');

      // Get IP
      const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim()
        || req.socket?.remoteAddress
        || 'unknown';

      const result = await handleRequest({ body, ip });

      res.writeHead(result.status, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(result.body));
      return true;
    };
  }

  return { handleRequest, createNodeHandler };
}

module.exports = { createHandler };
