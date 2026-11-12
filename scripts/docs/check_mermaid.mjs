#!/usr/bin/env node
/**
 * Home-Automation-SoC — validate the Mermaid block that GitHub will render.
 *
 * The block inside README.md is what GitHub parses, so it is the one that
 * matters. This extracts it and renders it with mermaid-cli, the same parser
 * GitHub uses.
 *
 * Usage:
 *   node scripts/docs/check_mermaid.mjs                 # validate the README
 *   node scripts/docs/check_mermaid.mjs --png out.png   # and render a PNG
 */

import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, "..", "..");
const README = join(ROOT, "README.md");
const SOURCE = join(ROOT, "docs", "architecture", "BLOCK_DIAGRAM.md");
const MMDC = join("D:\\tools\\mermaid", "node_modules", ".bin", "mmdc.cmd");
const CHROME = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";

const args = process.argv.slice(2);
const pngIndex = args.indexOf("--png");
const png = pngIndex >= 0 ? args[pngIndex + 1] : null;

if (!existsSync(README)) {
  console.error(`check_mermaid: ${README} not found`);
  process.exit(2);
}
if (!existsSync(MMDC)) {
  console.error("check_mermaid: mermaid-cli not found at D:\\tools\\mermaid");
  console.error("  install with:");
  console.error("    cd /d D:\\tools\\mermaid && npm install @mermaid-js/mermaid-cli");
  process.exit(2);
}

function puppeteerConfig() {
  const path = join("D:\\tools\\mermaid", "puppeteer.json");
  if (!existsSync(path)) {
    writeFileSync(
      path,
      JSON.stringify({ executablePath: CHROME, args: ["--no-sandbox"] }, null, 2),
    );
  }
  return path;
}

/** Pull the mermaid block out of a markdown file. */
function extract(text) {
  const start = text.indexOf("```mermaid");
  if (start < 0) return null;
  const bodyStart = text.indexOf("\n", start) + 1;
  const end = text.indexOf("```", bodyStart);
  if (end < 0) return null;
  return text.slice(bodyStart, end).replace(/\s+$/, "");
}

/**
 * Lint: an edge label that contains "[" or "]" must be quoted. Unquoted, the
 * parser terminates the label early and GitHub shows
 * "Unable to render rich display".
 */
function lintEdgeLabels(text, where) {
  const bad = [];
  for (const [index, line] of text.split("\n").entries()) {
    if (!/-->|-\.->|---|-\.-/.test(line)) continue;
    const match = line.match(/\|([^"|]*[\[\]][^"|]*)\|/);
    if (match) bad.push(`${where}:${index + 1}: ${line.trim()}`);
  }
  return bad;
}

const problems = [];

// 1. lint the standalone source
if (existsSync(SOURCE)) {
  const source = extract(readFileSync(SOURCE, "utf8"));
  if (!source) {
    problems.push("docs/architecture/BLOCK_DIAGRAM.md has no ```mermaid block");
  } else {
    problems.push(...lintEdgeLabels(source, "BLOCK_DIAGRAM.md"));
  }
}

// 2. lint and render the README block
const readme = readFileSync(README, "utf8");
const block = extract(readme);
if (!block) {
  problems.push("README.md has no ```mermaid block");
} else {
  problems.push(...lintEdgeLabels(block, "README.md"));

  const tmp = join("D:\\tools\\mermaid", "readme-diagram.mmd");
  writeFileSync(tmp, block + "\n", "utf8");

  console.log("check_mermaid: rendering the README diagram with mermaid-cli");
  const mmdcArgs = ["/c", MMDC, "-i", tmp, "-b", "transparent"];
  if (png) {
    const out = resolve(ROOT, png);
    mkdirSync(dirname(out), { recursive: true });
    mmdcArgs.push("-o", out);
  }
  mmdcArgs.push("-p", puppeteerConfig());

  try {
    const out = execFileSync("cmd.exe", mmdcArgs, {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    if (out.trim()) console.log(out.trim());
  } catch (error) {
    console.error("check_mermaid: the README diagram FAILED to render");
    console.error(error.stderr || error.message);
    problems.push("README diagram did not render");
  }
}

if (problems.length) {
  console.error("check_mermaid: problems found");
  problems.forEach((line) => console.error("  " + line));
  process.exit(1);
}

console.log("check_mermaid: OK — the README diagram renders" + (png ? ` (saved ${png})` : ""));
