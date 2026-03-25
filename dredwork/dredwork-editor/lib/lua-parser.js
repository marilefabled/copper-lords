/**
 * Bloodweight Lua Config Parser
 * Extracts editable text strings from Lua data files.
 * Handles the subset of Lua used in config tables:
 *   - String literals (double/single quoted, long strings)
 *   - Numbers, booleans, nil
 *   - Table constructors { }
 *   - Function bodies (skipped as opaque)
 *   - Comments (skipped)
 */

// ── Token Types ──────────────────────────────────────────────
const T = {
  STRING: 'string',
  NUMBER: 'number',
  BOOL: 'bool',
  NIL: 'nil',
  IDENT: 'ident',
  SYMBOL: 'symbol',
  KEYWORD: 'keyword',
  EOF: 'eof',
};

const KEYWORDS = new Set([
  'return', 'local', 'function', 'end', 'if', 'then', 'else', 'elseif',
  'for', 'while', 'do', 'repeat', 'until', 'and', 'or', 'not', 'in',
]);

const BLOCK_OPENERS = new Set(['function', 'if', 'for', 'while', 'repeat', 'do']);

// ── Tokenizer ────────────────────────────────────────────────

function tokenize(source) {
  const tokens = [];
  let i = 0;
  const len = source.length;

  while (i < len) {
    // Skip whitespace
    if (/\s/.test(source[i])) { i++; continue; }

    // Skip comments
    if (source[i] === '-' && source[i + 1] === '-') {
      if (source[i + 2] === '[' && source[i + 3] === '[') {
        // Block comment --[[ ... ]]
        const end = source.indexOf(']]', i + 4);
        i = end === -1 ? len : end + 2;
      } else {
        // Line comment
        while (i < len && source[i] !== '\n') i++;
      }
      continue;
    }

    // String: double-quoted
    if (source[i] === '"') {
      const start = i;
      i++; // skip opening quote
      let str = '';
      while (i < len && source[i] !== '"') {
        if (source[i] === '\\') {
          i++; // skip escape char
          if (source[i] === 'n') str += '\n';
          else if (source[i] === 't') str += '\t';
          else if (source[i] === '\\') str += '\\';
          else if (source[i] === '"') str += '"';
          else str += source[i] || '';
          i++;
        } else {
          str += source[i];
          i++;
        }
      }
      i++; // skip closing quote
      tokens.push({ type: T.STRING, value: str, start, end: i, raw: source.slice(start, i) });
      continue;
    }

    // String: single-quoted
    if (source[i] === "'") {
      const start = i;
      i++;
      let str = '';
      while (i < len && source[i] !== "'") {
        if (source[i] === '\\') {
          i++;
          if (source[i] === 'n') str += '\n';
          else if (source[i] === 't') str += '\t';
          else if (source[i] === '\\') str += '\\';
          else if (source[i] === "'") str += "'";
          else str += source[i] || '';
          i++;
        } else {
          str += source[i];
          i++;
        }
      }
      i++;
      tokens.push({ type: T.STRING, value: str, start, end: i, raw: source.slice(start, i) });
      continue;
    }

    // String: long string [[ ... ]]
    if (source[i] === '[' && source[i + 1] === '[') {
      const start = i;
      i += 2;
      const endIdx = source.indexOf(']]', i);
      const str = endIdx === -1 ? source.slice(i) : source.slice(i, endIdx);
      i = endIdx === -1 ? len : endIdx + 2;
      tokens.push({ type: T.STRING, value: str, start, end: i, raw: source.slice(start, i) });
      continue;
    }

    // Number (including negative)
    if (/[0-9]/.test(source[i]) || (source[i] === '-' && i + 1 < len && /[0-9]/.test(source[i + 1]) && tokens.length > 0 && tokens[tokens.length - 1].type === T.SYMBOL)) {
      const start = i;
      if (source[i] === '-') i++;
      while (i < len && /[0-9.]/.test(source[i])) i++;
      tokens.push({ type: T.NUMBER, value: parseFloat(source.slice(start, i)), start, end: i });
      continue;
    }

    // Identifier / keyword / bool / nil
    if (/[a-zA-Z_]/.test(source[i])) {
      const start = i;
      while (i < len && /[a-zA-Z0-9_]/.test(source[i])) i++;
      const word = source.slice(start, i);
      if (word === 'true' || word === 'false') {
        tokens.push({ type: T.BOOL, value: word === 'true', start, end: i });
      } else if (word === 'nil') {
        tokens.push({ type: T.NIL, value: null, start, end: i });
      } else if (KEYWORDS.has(word)) {
        tokens.push({ type: T.KEYWORD, value: word, start, end: i });
      } else {
        tokens.push({ type: T.IDENT, value: word, start, end: i });
      }
      continue;
    }

    // Symbols
    if ('{}[]()=,;:.#<>~+-*/%^'.includes(source[i])) {
      // Handle >= <= ~= == ..
      if (i + 1 < len) {
        const two = source.slice(i, i + 2);
        if (['>=', '<=', '~=', '==', '..'].includes(two)) {
          tokens.push({ type: T.SYMBOL, value: two, start: i, end: i + 2 });
          i += 2;
          continue;
        }
      }
      tokens.push({ type: T.SYMBOL, value: source[i], start: i, end: i + 1 });
      i++;
      continue;
    }

    // Unknown char — skip
    i++;
  }

  tokens.push({ type: T.EOF, value: null, start: i, end: i });
  return tokens;
}

// ── Parser ───────────────────────────────────────────────────

class Parser {
  constructor(tokens, source) {
    this.tokens = tokens;
    this.source = source;
    this.pos = 0;
  }

  peek() { return this.tokens[this.pos] || { type: T.EOF }; }
  advance() { return this.tokens[this.pos++] || { type: T.EOF }; }

  expect(type, value) {
    const t = this.advance();
    if (t.type !== type || (value !== undefined && t.value !== value)) {
      throw new Error(`Expected ${type}:${value} at pos ${t.start}, got ${t.type}:${t.value}`);
    }
    return t;
  }

  match(type, value) {
    const t = this.peek();
    if (t.type === type && (value === undefined || t.value === value)) {
      return this.advance();
    }
    return null;
  }

  // Skip function body by counting block openers/end keywords
  skipFunctionBody() {
    let depth = 1;
    while (depth > 0 && this.peek().type !== T.EOF) {
      const t = this.advance();
      if (t.type === T.KEYWORD && BLOCK_OPENERS.has(t.value)) depth++;
      if (t.type === T.KEYWORD && t.value === 'end') depth--;
    }
  }

  // Parse a value: string, number, bool, nil, table, function (opaque)
  parseValue() {
    const t = this.peek();

    if (t.type === T.STRING) {
      this.advance();
      return { type: 'string', value: t.value, start: t.start, end: t.end, raw: t.raw };
    }
    if (t.type === T.NUMBER) {
      this.advance();
      return { type: 'number', value: t.value };
    }
    if (t.type === T.BOOL) {
      this.advance();
      return { type: 'boolean', value: t.value };
    }
    if (t.type === T.NIL) {
      this.advance();
      return { type: 'nil', value: null };
    }

    // Negative number: - followed by number
    if (t.type === T.SYMBOL && t.value === '-') {
      const next = this.tokens[this.pos + 1];
      if (next && next.type === T.NUMBER) {
        this.advance(); // skip -
        this.advance(); // skip number
        return { type: 'number', value: -next.value };
      }
    }

    // Table constructor
    if (t.type === T.SYMBOL && t.value === '{') {
      return this.parseTable();
    }

    // Function (opaque — skip body)
    if (t.type === T.KEYWORD && t.value === 'function') {
      this.advance();
      // Skip params
      if (this.match(T.SYMBOL, '(')) {
        while (!this.match(T.SYMBOL, ')') && this.peek().type !== T.EOF) this.advance();
      }
      this.skipFunctionBody();
      return { type: 'function', value: '[function]' };
    }

    // Identifier reference (e.g., PRIORITY.rare)
    if (t.type === T.IDENT) {
      let val = this.advance().value;
      while (this.match(T.SYMBOL, '.')) {
        const next = this.advance();
        val += '.' + next.value;
      }
      // Handle function call: ident(...)
      if (this.peek().type === T.SYMBOL && this.peek().value === '(') {
        this.advance();
        let depth = 1;
        while (depth > 0 && this.peek().type !== T.EOF) {
          const tt = this.advance();
          if (tt.type === T.SYMBOL && tt.value === '(') depth++;
          if (tt.type === T.SYMBOL && tt.value === ')') depth--;
        }
      }
      return { type: 'reference', value: val };
    }

    // Hash operator #
    if (t.type === T.SYMBOL && t.value === '#') {
      this.advance();
      return this.parseValue(); // skip and parse next
    }

    // Fallback: skip
    this.advance();
    return { type: 'unknown', value: t.value };
  }

  // Parse table constructor { ... }
  parseTable() {
    this.expect(T.SYMBOL, '{');
    const entries = [];
    const tableStart = this.tokens[this.pos - 1].start;
    let arrayIndex = 0;

    while (this.peek().type !== T.EOF && !(this.peek().type === T.SYMBOL && this.peek().value === '}')) {
      // Try key = value
      const saved = this.pos;
      let key = null;

      if (this.peek().type === T.IDENT) {
        const ident = this.peek();
        const next = this.tokens[this.pos + 1];
        if (next && next.type === T.SYMBOL && next.value === '=') {
          this.advance(); // ident
          this.advance(); // =
          key = ident.value;
        }
      } else if (this.peek().type === T.SYMBOL && this.peek().value === '[') {
        this.advance(); // [
        const keyVal = this.parseValue();
        this.expect(T.SYMBOL, ']');
        this.expect(T.SYMBOL, '=');
        key = keyVal.type === 'string' ? keyVal.value : keyVal.value;
      }

      if (key === null) {
        // Array element
        this.pos = saved;
        arrayIndex++;
        key = arrayIndex;
      }

      const value = this.parseValue();
      entries.push({ key, value });

      // Skip comma or semicolon
      this.match(T.SYMBOL, ',') || this.match(T.SYMBOL, ';');
    }

    const closeBrace = this.expect(T.SYMBOL, '}');
    return { type: 'table', entries, start: tableStart, end: closeBrace.end };
  }

  // Parse top-level: find return { ... } or local X = { ... } or Module.X = { ... }
  parseFile() {
    const results = [];

    while (this.peek().type !== T.EOF) {
      const t = this.peek();

      // return { ... }
      if (t.type === T.KEYWORD && t.value === 'return') {
        this.advance();
        if (this.peek().type === T.SYMBOL && this.peek().value === '{') {
          const table = this.parseTable();
          results.push({ name: '_return', table });
        }
        continue;
      }

      // local X = { ... } or X.Y = { ... }
      if (t.type === T.KEYWORD && t.value === 'local') {
        this.advance();
        if (this.peek().type === T.IDENT) {
          const name = this.advance().value;
          if (this.match(T.SYMBOL, '=')) {
            if (this.peek().type === T.SYMBOL && this.peek().value === '{') {
              const table = this.parseTable();
              results.push({ name, table });
            } else {
              this.parseValue(); // skip non-table value
            }
          }
        }
        continue;
      }

      // Top-level function definition: function Name(...) ... end
      if (t.type === T.KEYWORD && t.value === 'function') {
        this.advance();
        // Skip function name (e.g., Foo.bar or Foo:bar)
        while (this.peek().type === T.IDENT || (this.peek().type === T.SYMBOL && (this.peek().value === '.' || this.peek().value === ':'))) {
          this.advance();
        }
        // Skip params
        if (this.match(T.SYMBOL, '(')) {
          while (!this.match(T.SYMBOL, ')') && this.peek().type !== T.EOF) this.advance();
        }
        this.skipFunctionBody();
        continue;
      }

      // Top-level for/if/while/repeat blocks (skip)
      if (t.type === T.KEYWORD && BLOCK_OPENERS.has(t.value) && t.value !== 'function') {
        this.advance();
        this.skipFunctionBody(); // reuses block-depth counting
        continue;
      }

      // Module.field = { ... }
      if (t.type === T.IDENT) {
        const saved = this.pos;
        let name = this.advance().value;
        while (this.match(T.SYMBOL, '.')) {
          name += '.' + this.advance().value;
        }
        if (this.match(T.SYMBOL, '=')) {
          if (this.peek().type === T.SYMBOL && this.peek().value === '{') {
            const table = this.parseTable();
            results.push({ name, table });
          } else {
            this.parseValue();
          }
        } else {
          this.pos = saved;
          this.advance();
        }
        continue;
      }

      this.advance();
    }

    return results;
  }
}

// ── Text Entry Extraction ────────────────────────────────────

const TEXT_FIELDS = new Set([
  'title', 'narrative', 'label', 'description', 'name', 'text',
  'reason', 'opening',
]);

/**
 * Extract all editable text entries from a parsed file.
 * Returns flat array of { path, field, value, start, end, raw }
 */
function extractStrings(parsed, filePath) {
  const entries = [];

  function walk(node, path) {
    if (!node) return;

    if (node.type === 'string' && node.start !== undefined) {
      entries.push({
        path: path,
        value: node.value,
        start: node.start,
        end: node.end,
        raw: node.raw,
        file: filePath,
      });
    }

    if (node.type === 'table') {
      for (const entry of node.entries) {
        const key = entry.key;
        const childPath = typeof key === 'number' ? `${path}[${key}]` : `${path}.${key}`;
        walk(entry.value, childPath);
      }
    }
  }

  for (const block of parsed) {
    walk(block.table, block.name);
  }

  return entries;
}

/**
 * Get a structured representation of the data for the UI.
 * Groups entries by their parent event/action ID.
 */
function extractStructured(parsed, filePath, fileType) {
  const groups = [];

  function getTableValue(table, key) {
    if (!table || table.type !== 'table') return null;
    for (const e of table.entries) {
      if (e.key === key) return e.value;
    }
    return null;
  }

  function collectTextFields(table, path, fields) {
    if (!table || table.type !== 'table') return;
    for (const entry of table.entries) {
      const key = entry.key;
      const val = entry.value;
      const childPath = typeof key === 'number' ? `${path}[${key}]` : `${path}.${key}`;

      if (val.type === 'string' && val.start !== undefined) {
        const isTextField = TEXT_FIELDS.has(key) ||
          (typeof key === 'number') || // array string = pool entry
          key === 'narrative';
        if (isTextField || path.includes('titles') || path.includes('consequences') || path.includes('options')) {
          fields.push({
            field: typeof key === 'number' ? `[${key}]` : key,
            path: childPath,
            value: val.value,
            start: val.start,
            end: val.end,
            raw: val.raw,
            file: filePath,
          });
        }
      }

      if (val.type === 'table') {
        collectTextFields(val, childPath, fields);
      }
    }
  }

  for (const block of parsed) {
    if (block.table.type !== 'table') continue;

    if (fileType === 'events' || fileType === 'council' || fileType === 'rites') {
      // Array of event/action objects
      for (const entry of block.table.entries) {
        if (entry.value.type !== 'table') continue;
        const id = getTableValue(entry.value, 'id');
        const title = getTableValue(entry.value, 'title') || getTableValue(entry.value, 'label') || getTableValue(entry.value, 'name');
        const category = getTableValue(entry.value, 'category');

        const fields = [];
        collectTextFields(entry.value, `${block.name}[${entry.key}]`, fields);

        if (fields.length > 0) {
          groups.push({
            id: id ? id.value : `entry_${entry.key}`,
            title: title ? title.value : `Entry ${entry.key}`,
            category: category ? category.value : null,
            fields,
            tableStart: entry.value.start,
            tableEnd: entry.value.end,
          });
        }
      }
    } else if (fileType === 'summaries') {
      // Keyed pools: TRAIT_ID = { "lvl1", "lvl2", ... }
      for (const entry of block.table.entries) {
        if (entry.value.type !== 'table') continue;
        const fields = [];
        const levels = ['Abysmal', 'Weak', 'Decent', 'Strong', 'Legendary'];
        for (const sub of entry.value.entries) {
          if (sub.value.type === 'string') {
            fields.push({
              field: levels[sub.key - 1] || `Level ${sub.key}`,
              path: `${block.name}.${entry.key}[${sub.key}]`,
              value: sub.value.value,
              start: sub.value.start,
              end: sub.value.end,
              raw: sub.value.raw,
              file: filePath,
            });
          }
        }
        if (fields.length > 0) {
          groups.push({
            id: entry.key,
            title: entry.key,
            category: 'trait',
            fields,
          });
        }
      }
    } else if (fileType === 'pools') {
      // Keyed string arrays: KEY = { "str1", "str2", ... }
      for (const entry of block.table.entries) {
        if (entry.value.type !== 'table') continue;
        const fields = [];
        collectTextFields(entry.value, `${block.name}.${entry.key}`, fields);
        if (fields.length > 0) {
          groups.push({
            id: entry.key,
            title: String(entry.key).replace(/_/g, ' '),
            category: fileType,
            fields,
          });
        }
      }
    } else if (fileType === 'legends') {
      // Array of legend objects with titles arrays
      for (const entry of block.table.entries) {
        if (entry.value.type !== 'table') continue;
        const id = getTableValue(entry.value, 'id');
        const cat = getTableValue(entry.value, 'category');
        const fields = [];

        // Only collect titles array strings
        const titlesNode = getTableValue(entry.value, 'titles');
        if (titlesNode && titlesNode.type === 'table') {
          for (const sub of titlesNode.entries) {
            if (sub.value.type === 'string') {
              fields.push({
                field: `Title ${sub.key}`,
                path: `${block.name}[${entry.key}].titles[${sub.key}]`,
                value: sub.value.value,
                start: sub.value.start,
                end: sub.value.end,
                raw: sub.value.raw,
                file: filePath,
              });
            }
          }
        }
        if (fields.length > 0) {
          groups.push({
            id: id ? id.value : `legend_${entry.key}`,
            title: id ? id.value.replace(/_/g, ' ') : `Legend ${entry.key}`,
            category: cat ? cat.value : 'legend',
            fields,
          });
        }
      }
    } else if (fileType === 'tutorial') {
      // tips = { key = { text = "...", position = "..." } }
      for (const entry of block.table.entries) {
        if (entry.value.type !== 'table') continue;
        const textNode = getTableValue(entry.value, 'text');
        if (textNode && textNode.type === 'string') {
          groups.push({
            id: entry.key,
            title: String(entry.key).replace(/_/g, ' '),
            category: 'tutorial',
            fields: [{
              field: 'text',
              path: `${block.name}.${entry.key}.text`,
              value: textNode.value,
              start: textNode.start,
              end: textNode.end,
              raw: textNode.raw,
              file: filePath,
            }],
          });
        }
      }
    } else {
      // Generic: collect all strings
      const fields = [];
      collectTextFields(block.table, block.name, fields);
      if (fields.length > 0) {
        groups.push({
          id: block.name,
          title: block.name,
          category: 'other',
          fields,
        });
      }
    }
  }

  return groups;
}

// ── Public API ───────────────────────────────────────────────

function parseFile(source, filePath, fileType) {
  const tokens = tokenize(source);
  const parser = new Parser(tokens, source);
  const parsed = parser.parseFile();
  return extractStructured(parsed, filePath, fileType);
}

function parseFileRaw(source) {
  const tokens = tokenize(source);
  const parser = new Parser(tokens, source);
  return parser.parseFile();
}

module.exports = { parseFile, parseFileRaw, tokenize, extractStrings };
