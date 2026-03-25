/**
 * dredwork-aibridge: AI Generator
 * Server-side module for sending decoded payloads to an AI for narrative generation.
 *
 * HOOKS (all provided via createGenerator options):
 *   buildSystemPrompt()              Required. Returns the system prompt string.
 *   buildUserMessage(rawPayload)     Required. Returns the user message string.
 *   parseOutput(text)                Optional. Custom parser for AI response → structured output.
 *   onTokenUsage({ input, output })  Optional. Called with token counts after generation.
 *
 * Supports:
 *   - Anthropic Claude API (default)
 *   - Custom API via `callAI` hook
 *   - Streaming with heartbeat for edge runtimes
 *   - Graceful fallback: structured JSON → regex extract → flat prose
 */

/**
 * Create an AI generator with hooks.
 * @param {object} opts
 * @param {function} opts.buildSystemPrompt () -> string. Required.
 * @param {function} opts.buildUserMessage (rawPayload) -> string. Required.
 * @param {function} opts.parseOutput (text) -> object|null. Optional structured parser.
 * @param {function} opts.onTokenUsage ({ input, output }) -> void. Optional.
 * @param {function} opts.callAI ({ system, user, maxTokens }) -> { text, inputTokens, outputTokens, stopReason }. Optional custom AI caller.
 * @param {string} opts.model AI model ID. Default: "claude-sonnet-4-6".
 * @param {number} opts.maxTokens Max output tokens. Default: 8192.
 * @param {string} opts.apiKey Anthropic API key. Read from ANTHROPIC_API_KEY env if not set.
 * @returns {object} Generator with generate() method
 */
function createGenerator(opts = {}) {
  const {
    buildSystemPrompt,
    buildUserMessage,
    parseOutput,
    onTokenUsage,
    callAI,
    model = 'claude-sonnet-4-6',
    maxTokens = 8192,
    apiKey,
  } = opts;

  if (!buildSystemPrompt) throw new Error('buildSystemPrompt hook is required');
  if (!buildUserMessage) throw new Error('buildUserMessage hook is required');

  /**
   * Default Claude API caller using @anthropic-ai/sdk.
   */
  async function defaultCallAI({ system, user, maxTokens: mt }) {
    let Anthropic;
    try {
      Anthropic = require('@anthropic-ai/sdk');
    } catch (e) {
      throw new Error(
        'Install @anthropic-ai/sdk to use the default AI caller, or provide a custom callAI hook.'
      );
    }

    const client = new Anthropic({ apiKey: apiKey || process.env.ANTHROPIC_API_KEY });

    const response = await client.messages.create({
      model,
      max_tokens: mt || maxTokens,
      system,
      messages: [{ role: 'user', content: user }],
    });

    const text = response.content
      .filter((c) => c.type === 'text')
      .map((c) => c.text)
      .join('');

    return {
      text,
      inputTokens: response.usage?.input_tokens || 0,
      outputTokens: response.usage?.output_tokens || 0,
      stopReason: response.stop_reason || 'end_turn',
    };
  }

  /**
   * Strip markdown code fences from AI output.
   */
  function stripCodeFences(text) {
    return text.replace(/^```(?:json)?\s*\n?/gm, '').replace(/\n?```\s*$/gm, '').trim();
  }

  /**
   * Try to extract JSON from text (AI sometimes wraps in prose).
   */
  function extractJSON(text) {
    // Try direct parse
    try {
      return JSON.parse(text);
    } catch (e) {
      // Ignore
    }

    // Try after stripping code fences
    try {
      return JSON.parse(stripCodeFences(text));
    } catch (e) {
      // Ignore
    }

    // Try regex: find first { ... } block
    const match = text.match(/\{[\s\S]*\}/);
    if (match) {
      try {
        return JSON.parse(match[0]);
      } catch (e) {
        // Ignore
      }
    }

    return null;
  }

  /**
   * Generate narrative from a raw payload.
   * @param {object|string} rawPayload The decoded game data (object or JSON string)
   * @returns {Promise<GenerateResult>}
   *
   * @typedef {object} GenerateResult
   * @property {boolean} success
   * @property {string} [prose] Full text output
   * @property {object} [structured] Parsed structured output (if parseOutput succeeds)
   * @property {string} [error] Error message
   * @property {number} [inputTokens]
   * @property {number} [outputTokens]
   */
  async function generate(rawPayload) {
    try {
      const system = buildSystemPrompt();
      const payloadStr = typeof rawPayload === 'string' ? rawPayload : JSON.stringify(rawPayload);
      const user = buildUserMessage(payloadStr);

      const caller = callAI || defaultCallAI;
      const result = await caller({ system, user, maxTokens });

      const { text, inputTokens, outputTokens, stopReason } = result;

      if (onTokenUsage) {
        try {
          onTokenUsage({ input: inputTokens, output: outputTokens });
        } catch (e) {
          // Non-fatal
        }
      }

      // Handle truncation
      let prose = text;
      if (stopReason === 'max_tokens') {
        prose += '\n\n[Output truncated due to length limit.]';
      }

      // Try to parse structured output
      let structured = null;
      if (parseOutput) {
        try {
          structured = parseOutput(prose);
        } catch (e) {
          // Fall through to JSON extraction
        }
      }

      if (!structured) {
        const jsonObj = extractJSON(prose);
        if (jsonObj) {
          structured = jsonObj;
        }
      }

      return {
        success: true,
        prose: stripCodeFences(prose),
        structured,
        inputTokens,
        outputTokens,
      };
    } catch (e) {
      return {
        success: false,
        error: e.message || String(e),
      };
    }
  }

  return { generate };
}

module.exports = { createGenerator };
