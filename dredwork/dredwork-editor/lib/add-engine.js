/**
 * dredwork-editor — Add Entry Engine
 * Inserts new entries into Lua source files using config-defined templates.
 *
 * Three insertion strategies:
 *   before_last_brace  — Insert before the final } in the file (events, council)
 *   into_pool           — Find a named pool table, insert before its closing }
 *   into_legend_titles  — Find a legend by id, insert into its titles array
 */

const fs = require('fs');
const path = require('path');

/**
 * Add a new entry to a Lua source file.
 * @param {string} projectRoot Absolute path to project
 * @param {string} filePath Relative file path
 * @param {string} fileType File type key from config
 * @param {object} data Form data from the add modal
 * @param {object} templates Config templates object (keyed by fileType)
 * @returns {{ success: boolean }}
 */
function addEntry(projectRoot, filePath, fileType, data, templates) {
  const absPath = path.join(projectRoot, filePath);
  let source = fs.readFileSync(absPath, 'utf8');
  const tmplDef = templates[fileType];

  if (!tmplDef) {
    throw new Error(`No add template defined for file type: ${fileType}`);
  }

  const strategy = tmplDef.strategy || 'before_last_brace';

  if (strategy === 'before_last_brace') {
    // Pick template string — support variants via data flags
    let templateStr = tmplDef.template;
    if (data.hasOptions && tmplDef.template_multi) {
      templateStr = tmplDef.template_multi;
    }

    // Replace all __PLACEHOLDER__ tokens with data values
    let entry = templateStr;
    for (const [key, val] of Object.entries(data)) {
      if (typeof val === 'string') {
        entry = entry.replace(new RegExp(`__${key.toUpperCase()}__`, 'g'), val);
      }
    }

    const lastBrace = source.lastIndexOf('}');
    source = source.slice(0, lastBrace) + '\n' + entry + '\n' + source.slice(lastBrace);

  } else if (strategy === 'into_pool') {
    const poolKey = data.pool;
    const lineTemplate = tmplDef.line_template || '        "__TEXT__",';
    const newLine = lineTemplate.replace('__TEXT__', data.text || 'New entry.');

    const pattern = new RegExp(`(${poolKey}\\s*=\\s*\\{)`);
    const match = source.match(pattern);
    if (match) {
      let depth = 0;
      let idx = source.indexOf(match[0]) + match[0].length;
      while (idx < source.length) {
        if (source[idx] === '{') depth++;
        if (source[idx] === '}') {
          if (depth === 0) {
            source = source.slice(0, idx) + newLine + '\n    ' + source.slice(idx);
            break;
          }
          depth--;
        }
        idx++;
      }
    }

  } else if (strategy === 'into_legend_titles') {
    const lineTemplate = tmplDef.line_template || '            "__TEXT__",';
    if (data.legendId) {
      const idPattern = `id = "${data.legendId}"`;
      const idIdx = source.indexOf(idPattern);
      if (idIdx !== -1) {
        const titlesIdx = source.indexOf('titles = {', idIdx);
        if (titlesIdx !== -1) {
          const closeBrace = source.indexOf('}', titlesIdx + 10);
          const newTitle = lineTemplate.replace('__TEXT__', data.text || 'New Title');
          source = source.slice(0, closeBrace) + newTitle + '\n        ' + source.slice(closeBrace);
        }
      }
    }
  }

  fs.writeFileSync(absPath, source, 'utf8');
  return { success: true };
}

module.exports = { addEntry };
