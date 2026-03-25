/**
 * dredwork-editor — Config Loader
 * Loads and validates dredwork-editor.config.js from a project root.
 */

const path = require('path');
const fs = require('fs');

const CONFIG_FILENAME = 'dredwork-editor.config.js';

const DEFAULTS = {
  name: 'Project',
  subtitle: 'Text Editor',
  port: 3333,
  files: [],
  templates: {},
  reference: {},
  colorWords: {},
  welcome: {
    heading: 'Text Editor',
    description: 'Select a file from the sidebar to begin editing. All changes write directly to the Lua source files.',
    tips: 'Use Ctrl+S to save the focused field. Open the Reference Key to see template variables and field guides.',
    footer: '',
  },
};

/**
 * Load config from a project root.
 * @param {string} projectRoot Absolute path to the project
 * @returns {object} Normalized config
 */
function loadConfig(projectRoot) {
  const configPath = path.join(projectRoot, CONFIG_FILENAME);

  if (!fs.existsSync(configPath)) {
    console.error(`\n  ERROR: ${CONFIG_FILENAME} not found at:\n  ${configPath}\n`);
    console.error(`  Create a ${CONFIG_FILENAME} in your project root to configure the editor.`);
    console.error(`  See the dredwork-editor README for the config schema.\n`);
    process.exit(1);
  }

  let raw;
  try {
    raw = require(configPath);
  } catch (e) {
    console.error(`\n  ERROR: Failed to load ${CONFIG_FILENAME}:\n  ${e.message}\n`);
    process.exit(1);
  }

  if (!raw.files || !Array.isArray(raw.files) || raw.files.length === 0) {
    console.error(`\n  ERROR: ${CONFIG_FILENAME} must define a non-empty "files" array.\n`);
    process.exit(1);
  }

  // Merge with defaults
  const config = {
    name: raw.name || DEFAULTS.name,
    subtitle: raw.subtitle || DEFAULTS.subtitle,
    port: raw.port || DEFAULTS.port,
    files: raw.files,
    templates: raw.templates || DEFAULTS.templates,
    reference: raw.reference || DEFAULTS.reference,
    colorWords: raw.colorWords || DEFAULTS.colorWords,
    welcome: Object.assign({}, DEFAULTS.welcome, raw.welcome || {}),
    theme: raw.theme || null,
  };

  return config;
}

module.exports = { loadConfig };
