# dredwork-aibridge

Game-to-AI narrative pipeline. Encode game state in Lua, decode on server, generate AI narratives — all via hooks.

Built for any game that wants to send run data to an AI and get structured narrative back. Zero project-specific code inside.

## Architecture

```
GAME (Lua)                              SERVER (Node.js)
┌──────────────┐                        ┌──────────────────┐
│ Your game    │                        │ payload-decoder   │
│ run_data     │                        │   decode()        │
│      │       │     DWAI1:RAW:...      │      │            │
│ ┌────▼─────┐ │  ──────────────────►   │ ┌────▼──────────┐ │
│ │ payload  │ │                        │ │ ai-generator   │ │
│ │ encoder  │ │                        │ │   generate()   │ │
│ └────┬─────┘ │                        │ └────┬──────────┘ │
│      │       │                        │      │            │
│ ┌────▼─────┐ │     { structured,      │ ┌────▼──────────┐ │
│ │ network  │ │  ◄──  prose, id }      │ │ api-handler    │ │
│ │ sender   │ │                        │ │   handle()     │ │
│ └──────────┘ │                        │ └───────────────┘ │
└──────────────┘                        └──────────────────┘
```

## Game Side (Lua)

### Payload Encoder

```lua
local Encoder = require("dredwork-aibridge.lua.payload_encoder")

-- Configure wire format
Encoder.configure({
  prefix = "MYGAME1",  -- Your game's wire prefix
  version = 1,
})

-- Set the extract hook — defines WHAT data gets packed
Encoder.set_hooks({
  extract = function(run_data)
    return {
      player = run_data.player_name,
      score = run_data.final_score,
      chapters = run_data.story_beats,
      death = run_data.cause_of_death,
    }
  end,
  to_json = my_json_library.encode,    -- optional: use your own JSON encoder
  from_json = my_json_library.decode,  -- optional: for decode()
})

-- Encode run data into wire format
local wire, err = Encoder.encode(run_data)
if wire then
  -- wire = "MYGAME1:RAW:a1b2c3d4:eyJwbGF5Z..."
end
```

### Network Sender

```lua
local Sender = require("dredwork-aibridge.lua.network_sender")

-- Optional: customize retry behavior
Sender.configure({
  max_retries = 3,
  backoff_ms = { 1500, 3000, 6000 },
})

-- Send with hooks
Sender.send("https://yoursite.com/api/generate", wire, {
  on_status = function(msg)
    status_label.text = msg
  end,
  on_success = function(data)
    open_url(data.url)
  end,
  on_fail = function(reason, payload)
    show_error(reason)
  end,
  on_fallback = function(payload)
    system.setClipboard(payload)  -- Solar2D clipboard fallback
  end,
})
```

## Server Side (Node.js)

### Quick Setup

```js
const aibridge = require('dredwork-aibridge/server');

// 1. Create decoder with optional transform
const decoder = aibridge.createDecoder({
  prefix: 'MYGAME1',
  transform: (raw) => ({
    playerName: raw.player,
    score: raw.score,
    storyBeats: raw.chapters,
  }),
});

// 2. Create AI generator with your voice
const generator = aibridge.createGenerator({
  buildSystemPrompt: () => `
    You are a narrator for a dark fantasy game.
    Given player run data, write a dramatic 3-paragraph epilogue.
    Return JSON: { "title": "...", "prose": "..." }
  `,
  buildUserMessage: (payloadJson) =>
    `The following run has ended. Write the epilogue.\n\n${payloadJson}`,
  model: 'claude-sonnet-4-6',
  maxTokens: 4096,
});

// 3. Create API handler
const handler = aibridge.createHandler({
  decoder,
  generator,
  store: async (record) => {
    // Save to your database
    await db.insert('narratives', record);
  },
  onGenerated: (result, rawPayload) => {
    console.log(`Generated ${result.outputTokens} tokens`);
  },
});

// 4. Mount on your server
const http = require('http');
const nodeHandler = handler.createNodeHandler('/api/generate');

http.createServer(async (req, res) => {
  const handled = await nodeHandler(req, res);
  if (!handled) {
    res.writeHead(404);
    res.end('Not found');
  }
}).listen(3000);
```

### With Express

```js
app.post('/api/generate', async (req, res) => {
  const result = await handler.handleRequest({
    body: JSON.stringify(req.body),
    ip: req.ip,
  });
  res.status(result.status).json(result.body);
});
```

### With SvelteKit

```js
// src/routes/api/generate/+server.js
export async function POST({ request }) {
  const body = await request.text();
  const ip = request.headers.get('x-forwarded-for') || 'unknown';
  const result = await handler.handleRequest({ body, ip });
  return new Response(JSON.stringify(result.body), {
    status: result.status,
    headers: { 'Content-Type': 'application/json' },
  });
}
```

## Hooks Reference

### Game Side

| Hook | Module | When |
|---|---|---|
| `extract(run_data)` | Encoder | Called to distill game state into payload. **Required.** |
| `on_encoded(wire)` | Encoder | After successful encoding |
| `to_json(table)` | Encoder | Custom JSON serializer |
| `from_json(str)` | Encoder | Custom JSON deserializer (for decode) |
| `on_status(msg)` | Sender | Status messages during retries |
| `on_success(data)` | Sender | Successful server response |
| `on_fail(reason, payload)` | Sender | All retries exhausted |
| `on_fallback(payload)` | Sender | Graceful degradation (clipboard, file, etc.) |
| `parse_response(body)` | Sender | Custom response parser |
| `is_success(data)` | Sender | Custom success condition check |

### Server Side

| Hook | Module | When |
|---|---|---|
| `transform(raw)` | Decoder | Transform decoded data into app-specific shape |
| `validate(raw)` | Decoder | Validate decoded payload before processing |
| `buildSystemPrompt()` | Generator | Build the AI system prompt. **Required.** |
| `buildUserMessage(json)` | Generator | Build the AI user message. **Required.** |
| `parseOutput(text)` | Generator | Custom parser for AI response |
| `onTokenUsage({ input, output })` | Generator | Token usage reporting |
| `callAI({ system, user, maxTokens })` | Generator | Replace default Claude API caller |
| `onReceive(raw)` | Handler | After decode, before generation. Return false to reject. |
| `onGenerated(result, raw)` | Handler | After AI generation completes |
| `store(record)` | Handler | Persist the record (received + completed states) |
| `generateId()` | Handler | Custom ID generation |
| `rateLimit(ip)` | Handler | Return false to reject request |

## Wire Format

```
DWAI1:RAW:a1b2c3d4:eyJwbGF5ZXIiOiJ...
  │    │     │          │
  │    │     │          └─ Base64url-encoded JSON payload
  │    │     └─ FNV-1a 32-bit checksum of pre-encoded JSON
  │    └─ Mode: RAW (uncompressed) or GZ (gzip)
  └─ Prefix (configurable per project)
```

## License

MIT
