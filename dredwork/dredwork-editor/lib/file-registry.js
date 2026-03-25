/**
 * dredwork-editor — File Registry Builder
 * Expands config file entries (including globs) into a flat registry.
 */

const fs = require('fs');
const path = require('path');

/**
 * Build a flat file registry from config entries.
 * @param {object[]} fileEntries Config `files` array
 * @param {string} projectRoot Absolute path to project
 * @returns {object[]} Array of { path, type, label, category, addable }
 */
function buildRegistry(fileEntries, projectRoot) {
  const registry = [];

  for (const entry of fileEntries) {
    if (entry.glob) {
      // Expand glob: "dir/*.lua" -> scan directory for matching files
      const globParts = entry.glob.split('*');
      const dir = globParts[0].replace(/\/$/, '');
      const ext = globParts[1] || '.lua';
      const absDir = path.join(projectRoot, dir);

      if (!fs.existsSync(absDir)) continue;

      const files = fs.readdirSync(absDir)
        .filter(f => f.endsWith(ext))
        .sort();

      for (const f of files) {
        const relPath = `${dir}/${f}`;
        const label = entry.labelTransform
          ? entry.labelTransform(f)
          : f.replace(ext, '').replace(/_/g, ' ');

        registry.push({
          path: relPath,
          type: entry.type,
          label: label,
          category: entry.category || 'Other',
          addable: entry.addable || false,
        });
      }
    } else if (entry.path) {
      // Single file entry
      const absPath = path.join(projectRoot, entry.path);
      if (!fs.existsSync(absPath)) continue;

      registry.push({
        path: entry.path,
        type: entry.type,
        label: entry.label || path.basename(entry.path, '.lua').replace(/_/g, ' '),
        category: entry.category || 'Other',
        addable: entry.addable || false,
      });
    }
  }

  return registry;
}

module.exports = { buildRegistry };
