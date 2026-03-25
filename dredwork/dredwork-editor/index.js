#!/usr/bin/env node
/**
 * dredwork-editor — CLI Entry Point
 *
 * Usage:
 *   npx dredwork-editor                  # runs from current directory
 *   npx dredwork-editor /path/to/project # runs from specified project root
 */

const path = require('path');
const { loadConfig } = require('./lib/config-loader');
const { startServer } = require('./lib/server');

// Resolve project root from CLI arg or cwd
const projectRoot = path.resolve(process.argv[2] || process.cwd());
const config = loadConfig(projectRoot);

startServer(config, projectRoot);
