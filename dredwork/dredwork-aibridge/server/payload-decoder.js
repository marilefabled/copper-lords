/**
 * dredwork-aibridge: Payload Decoder
 * Server-side module for decoding wire format payloads.
 *
 * HOOKS:
 *   transform(rawPayload) -> object   Optional. Transform decoded data into app-specific shape.
 *   validate(rawPayload) -> boolean   Optional. Custom validation after decode.
 *
 * Supports multiple input formats with fallback chain:
 *   1. Wire format (PREFIX:MODE:CHECKSUM:BASE64)
 *   2. Direct JSON object
 *   3. Base64-encoded JSON
 *   4. Text block with embedded JSON markers
 */

// ── Base64url ──
function base64urlDecode(str) {
  // Convert base64url to standard base64
  let b64 = str.replace(/-/g, '+').replace(/_/g, '/');
  const pad = 4 - (b64.length % 4);
  if (pad < 4) b64 += '='.repeat(pad);
  return Buffer.from(b64, 'base64').toString('utf8');
}

// ── FNV-1a 32-bit ──
function fnv1a(str) {
  let hash = 2166136261;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = Math.imul(hash, 16777619) >>> 0;
  }
  return hash.toString(16).padStart(8, '0');
}

/**
 * Create a decoder with optional hooks.
 * @param {object} opts
 * @param {string} opts.prefix Wire format prefix (default: "DWAI1")
 * @param {function} opts.transform Optional transform hook: (raw) -> enriched
 * @param {function} opts.validate Optional validation hook: (raw) -> boolean
 * @returns {object} Decoder with decode() method
 */
function createDecoder(opts = {}) {
  const prefix = opts.prefix || 'DWAI1';
  const transform = opts.transform || null;
  const validate = opts.validate || null;

  /**
   * Decode a wire format string.
   * @param {string} input Wire format, JSON string, or base64
   * @returns {{ payload: object, raw: object|null, error: string|null }}
   */
  function decode(input) {
    if (!input || typeof input !== 'string') {
      return { payload: null, raw: null, error: 'Empty or invalid input' };
    }

    const cleaned = input.replace(/\s+/g, '').trim();
    let rawPayload = null;

    // Strategy 1: Wire format (PREFIX:MODE:CHECKSUM:DATA)
    if (cleaned.startsWith(prefix + ':')) {
      try {
        const parts = cleaned.split(':');
        if (parts.length >= 4) {
          const [pfx, mode, checksum, ...dataParts] = parts;
          const data = dataParts.join(':');

          let jsonStr;
          if (mode === 'RAW') {
            jsonStr = base64urlDecode(data);
          } else if (mode === 'GZ') {
            // GZ mode: base64url → gunzip → JSON
            // Requires zlib — skip if not available
            try {
              const zlib = require('zlib');
              const buf = Buffer.from(data.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
              jsonStr = zlib.gunzipSync(buf).toString('utf8');
            } catch (e) {
              return { payload: null, raw: null, error: 'GZ decompression failed: ' + e.message };
            }
          } else {
            return { payload: null, raw: null, error: 'Unknown wire mode: ' + mode };
          }

          // Verify checksum
          const computed = fnv1a(jsonStr);
          if (computed !== checksum) {
            console.warn(`[dredwork-aibridge] Checksum mismatch: expected ${checksum}, got ${computed}`);
          }

          rawPayload = JSON.parse(jsonStr);
        }
      } catch (e) {
        // Fall through to other strategies
      }
    }

    // Strategy 2: Direct JSON
    if (!rawPayload) {
      try {
        const parsed = typeof input === 'string' ? JSON.parse(input) : input;
        if (parsed && typeof parsed === 'object') {
          rawPayload = parsed;
        }
      } catch (e) {
        // Fall through
      }
    }

    // Strategy 3: Base64-encoded JSON
    if (!rawPayload) {
      try {
        const decoded = base64urlDecode(cleaned);
        rawPayload = JSON.parse(decoded);
      } catch (e) {
        // Fall through
      }
    }

    // Strategy 4: Embedded JSON markers
    if (!rawPayload) {
      try {
        const startMarker = '--- DATA ---';
        const endMarker = '--- END ---';
        const startIdx = input.indexOf(startMarker);
        const endIdx = input.indexOf(endMarker);
        if (startIdx !== -1 && endIdx !== -1) {
          const jsonBlock = input.slice(startIdx + startMarker.length, endIdx).trim();
          rawPayload = JSON.parse(jsonBlock);
        }
      } catch (e) {
        // Fall through
      }
    }

    if (!rawPayload) {
      return { payload: null, raw: null, error: 'Could not decode input with any strategy' };
    }

    // Validate
    if (validate) {
      try {
        if (!validate(rawPayload)) {
          return { payload: null, raw: rawPayload, error: 'Validation failed' };
        }
      } catch (e) {
        return { payload: null, raw: rawPayload, error: 'Validation error: ' + e.message };
      }
    }

    // Transform
    let payload = rawPayload;
    if (transform) {
      try {
        payload = transform(rawPayload);
      } catch (e) {
        // Transform failed — use raw
        console.warn('[dredwork-aibridge] Transform failed, using raw payload:', e.message);
        payload = rawPayload;
      }
    }

    return { payload, raw: rawPayload, error: null };
  }

  return { decode };
}

module.exports = { createDecoder, base64urlDecode, fnv1a };
