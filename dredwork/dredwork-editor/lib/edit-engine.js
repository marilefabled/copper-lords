/**
 * dredwork-editor — Edit Engine
 * Applies text edits to Lua source files with position tracking.
 */

const fs = require('fs');
const path = require('path');

/**
 * Apply a text edit to a Lua source file.
 * @param {string} projectRoot Absolute path to project
 * @param {string} filePath Relative file path
 * @param {number} start Start offset in source
 * @param {number} end_ End offset in source
 * @param {string} oldRaw Original raw string (with quotes)
 * @param {string} newValue New decoded value (without quotes)
 * @returns {{ success: boolean, newRaw: string }}
 */
function applyEdit(projectRoot, filePath, start, end_, oldRaw, newValue) {
  const absPath = path.join(projectRoot, filePath);
  let source = fs.readFileSync(absPath, 'utf8');

  // Verify the old string is still at the expected position
  const found = source.slice(start, end_);
  if (found !== oldRaw) {
    // File changed since parse — try to find the old raw string
    const idx = source.indexOf(oldRaw);
    if (idx === -1) {
      throw new Error('Cannot find original text in file. File may have been modified externally.');
    }
    start = idx;
    end_ = idx + oldRaw.length;
  }

  // Determine quote style from original
  const quoteChar = oldRaw[0]; // " or ' or [
  let newRaw;
  if (quoteChar === '[') {
    newRaw = `[[${newValue}]]`;
  } else {
    // Escape the new value
    const escaped = newValue
      .replace(/\\/g, '\\\\')
      .replace(/\n/g, '\\n')
      .replace(/\t/g, '\\t');
    if (quoteChar === "'") {
      newRaw = `'${escaped.replace(/'/g, "\\'")}'`;
    } else {
      newRaw = `"${escaped.replace(/"/g, '\\"')}"`;
    }
  }

  source = source.slice(0, start) + newRaw + source.slice(end_);
  fs.writeFileSync(absPath, source, 'utf8');
  return { success: true, newRaw };
}

module.exports = { applyEdit };
