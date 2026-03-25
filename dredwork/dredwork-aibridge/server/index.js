/**
 * dredwork-aibridge — Server-side entry point
 *
 * Exports all server modules for easy consumption:
 *
 *   const aibridge = require('dredwork-aibridge/server');
 *   const decoder = aibridge.createDecoder({ prefix: 'MYGAME1', transform: ... });
 *   const generator = aibridge.createGenerator({ buildSystemPrompt: ..., buildUserMessage: ... });
 *   const handler = aibridge.createHandler({ decoder, generator, store: ... });
 */

const { createDecoder, base64urlDecode, fnv1a } = require('./payload-decoder');
const { createGenerator } = require('./ai-generator');
const { createHandler } = require('./api-handler');

module.exports = {
  createDecoder,
  createGenerator,
  createHandler,
  base64urlDecode,
  fnv1a,
};
