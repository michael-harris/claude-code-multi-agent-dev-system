#!/usr/bin/env node
// Cross-platform hook runner for DevTeam
// Detects OS and runs the appropriate .sh (Unix) or .ps1 (Windows) hook script.
// Always exits 0 on error — hooks must never block Claude Code.

import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const hookName = process.argv[2];

if (!hookName) {
  process.exit(0);
}

const isWindows = process.platform === 'win32';
const shScript = resolve(__dirname, `${hookName}.sh`);
const ps1Script = resolve(__dirname, `${hookName}.ps1`);

try {
  if (isWindows) {
    if (existsSync(ps1Script)) {
      execSync(
        `powershell -ExecutionPolicy Bypass -NoProfile -File "${ps1Script}"`,
        { stdio: 'inherit', timeout: 30000 }
      );
    }
  } else {
    if (existsSync(shScript)) {
      execSync(`bash "${shScript}"`, { stdio: 'inherit', timeout: 30000 });
    }
  }
} catch {
  // Hooks degrade gracefully — never block Claude Code
  process.exit(0);
}
