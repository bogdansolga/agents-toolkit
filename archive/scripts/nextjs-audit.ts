#!/usr/bin/env bun
/**
 * Next.js 16 Audit Script
 * Checks for performance, caching, and best practices compliance
 *
 * Usage: bun run scripts/nextjs-audit.ts [--fix]
 */

import { execSync } from "child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "fs";
import { join } from "path";

const ROOT = process.cwd();

// Find config file (supports .ts, .js, .mjs)
function findConfigFile(): string | null {
  for (const ext of [".ts", ".js", ".mjs"]) {
    const path = join(ROOT, `next.config${ext}`);
    if (existsSync(path)) return path;
  }
  return null;
}

// Find app directory (supports src/app and root app/)
function findAppDir(): string | null {
  const srcApp = join(ROOT, "src/app");
  const rootApp = join(ROOT, "app");
  if (existsSync(srcApp)) return srcApp;
  if (existsSync(rootApp)) return rootApp;
  return null;
}

// Find src directory (or root if no src)
function findSrcDir(): string {
  const src = join(ROOT, "src");
  return existsSync(src) ? src : ROOT;
}

const COLORS = {
  reset: "\x1b[0m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  dim: "\x1b[2m",
};

interface AuditResult {
  category: string;
  check: string;
  status: "pass" | "warn" | "fail" | "info";
  message: string;
  file?: string;
  line?: number;
}

const results: AuditResult[] = [];

function log(result: AuditResult) {
  results.push(result);
  const icon =
    result.status === "pass"
      ? `${COLORS.green}✓${COLORS.reset}`
      : result.status === "warn"
        ? `${COLORS.yellow}○${COLORS.reset}`
        : result.status === "fail"
          ? `${COLORS.red}✗${COLORS.reset}`
          : `${COLORS.blue}ℹ${COLORS.reset}`;

  const location = result.file ? ` ${COLORS.dim}(${result.file}${result.line ? `:${result.line}` : ""})${COLORS.reset}` : "";
  console.log(`  ${icon} ${result.message}${location}`);
}

function findFiles(dir: string, pattern: RegExp, ignore: string[] = []): string[] {
  const files: string[] = [];
  if (!existsSync(dir)) return files;

  const entries = readdirSync(dir);
  for (const entry of entries) {
    const fullPath = join(dir, entry);
    if (ignore.some((i) => fullPath.includes(i))) continue;

    const stat = statSync(fullPath);
    if (stat.isDirectory()) {
      files.push(...findFiles(fullPath, pattern, ignore));
    } else if (pattern.test(entry)) {
      files.push(fullPath);
    }
  }
  return files;
}

function grepFiles(pattern: RegExp, files: string[]): { file: string; line: number; content: string }[] {
  const matches: { file: string; line: number; content: string }[] = [];
  for (const file of files) {
    const content = readFileSync(file, "utf-8");
    const lines = content.split("\n");
    for (let i = 0; i < lines.length; i++) {
      if (pattern.test(lines[i])) {
        matches.push({ file: file.replace(ROOT + "/", ""), line: i + 1, content: lines[i].trim() });
      }
    }
  }
  return matches;
}

// ============================================================================
// Configuration Audit
// ============================================================================

function auditConfig() {
  console.log(`\n${COLORS.blue}═══ Configuration Audit ═══${COLORS.reset}`);

  const configPath = findConfigFile();
  if (!configPath) {
    log({ category: "config", check: "next.config", status: "fail", message: "next.config.{ts,js,mjs} not found" });
    return;
  }

  log({ category: "config", check: "configFile", status: "info", message: `Using ${configPath.replace(ROOT + "/", "")}` });
  const config = readFileSync(configPath, "utf-8");

  // React Compiler
  if (/reactCompiler:\s*true/.test(config)) {
    log({ category: "config", check: "reactCompiler", status: "pass", message: "React Compiler enabled" });
  } else {
    log({ category: "config", check: "reactCompiler", status: "fail", message: "React Compiler not enabled - add reactCompiler: true" });
  }

  // cacheComponents
  if (/cacheComponents:\s*true/.test(config)) {
    log({ category: "config", check: "cacheComponents", status: "pass", message: "cacheComponents enabled (PPR support)" });
  } else {
    log({ category: "config", check: "cacheComponents", status: "fail", message: "cacheComponents not enabled - add cacheComponents: true" });
  }

  // Turbopack FS cache
  if (/turbopackFileSystemCacheForDev:\s*true/.test(config)) {
    log({ category: "config", check: "turbopackCache", status: "pass", message: "Turbopack FS cache enabled" });
  } else {
    log({ category: "config", check: "turbopackCache", status: "warn", message: "Turbopack FS cache not enabled (optional)" });
  }

  // Image optimization
  if (/minimumCacheTTL/.test(config)) {
    log({ category: "config", check: "imageCacheTTL", status: "pass", message: "Custom image cache TTL configured" });
  } else {
    log({ category: "config", check: "imageCacheTTL", status: "warn", message: "Using default image cache TTL (consider increasing)" });
  }

  // Standalone output
  if (/output:\s*["']standalone["']/.test(config)) {
    log({ category: "config", check: "standalone", status: "pass", message: "Standalone output enabled (Docker-ready)" });
  } else {
    log({ category: "config", check: "standalone", status: "info", message: "Standalone output not enabled" });
  }
}

// ============================================================================
// Image Optimization Audit
// ============================================================================

function auditImages() {
  console.log(`\n${COLORS.blue}═══ Image Optimization Audit ═══${COLORS.reset}`);

  const srcDir = findSrcDir();
  const tsxFiles = findFiles(srcDir, /\.tsx$/, ["node_modules", ".next"]);

  // Check for unoptimized <img> tags
  const imgTags = grepFiles(/<img\s/, tsxFiles);
  if (imgTags.length === 0) {
    log({ category: "images", check: "imgTags", status: "pass", message: "No unoptimized <img> tags found" });
  } else {
    log({ category: "images", check: "imgTags", status: "fail", message: `Found ${imgTags.length} unoptimized <img> tags` });
    imgTags.slice(0, 5).forEach((m) => {
      log({ category: "images", check: "imgTag", status: "fail", message: `Unoptimized <img>`, file: m.file, line: m.line });
    });
    if (imgTags.length > 5) {
      log({ category: "images", check: "imgTags", status: "info", message: `... and ${imgTags.length - 5} more` });
    }
  }

  // Check next/image usage
  const nextImageImports = grepFiles(/from ["']next\/image["']/, tsxFiles);
  log({ category: "images", check: "nextImage", status: "info", message: `next/image imported in ${nextImageImports.length} files` });

  // Check for priority on above-fold images
  const pageFiles = tsxFiles.filter((f) => f.includes("/app/") && f.endsWith("page.tsx"));
  let priorityCount = 0;
  for (const file of pageFiles) {
    const content = readFileSync(file, "utf-8");
    if (/priority/.test(content)) priorityCount++;
  }
  if (priorityCount > 0) {
    log({ category: "images", check: "priority", status: "pass", message: `${priorityCount} pages use priority prop for LCP images` });
  } else {
    log({ category: "images", check: "priority", status: "warn", message: "Consider adding priority prop to above-fold images" });
  }
}

// ============================================================================
// Component Boundary Audit
// ============================================================================

function auditComponents() {
  console.log(`\n${COLORS.blue}═══ Component Boundary Audit ═══${COLORS.reset}`);

  const srcDir = findSrcDir();
  const tsxFiles = findFiles(srcDir, /\.tsx$/, ["node_modules", ".next"]);

  // Count client components
  const clientComponents = grepFiles(/"use client"/, tsxFiles);
  log({ category: "components", check: "clientCount", status: "info", message: `Client components: ${clientComponents.length}` });

  // Check for potentially unnecessary client components
  const clientHooks = /useState|useEffect|useContext|useReducer|useCallback|useMemo|useRef/;
  const eventHandlers = /onClick|onChange|onSubmit|onKeyDown|onMouseEnter/;

  let unnecessaryCount = 0;
  for (const match of clientComponents) {
    const fullPath = join(ROOT, match.file);
    const content = readFileSync(fullPath, "utf-8");
    if (!clientHooks.test(content) && !eventHandlers.test(content)) {
      log({
        category: "components",
        check: "unnecessaryClient",
        status: "warn",
        message: "May not need 'use client'",
        file: match.file,
      });
      unnecessaryCount++;
    }
  }

  if (unnecessaryCount === 0 && clientComponents.length > 0) {
    log({ category: "components", check: "clientUsage", status: "pass", message: "All client components use client features" });
  }

  // Check for server components with client hooks
  const serverWithHooks = tsxFiles.filter((f) => {
    const content = readFileSync(f, "utf-8");
    return !content.includes('"use client"') && clientHooks.test(content);
  });

  if (serverWithHooks.length > 0) {
    serverWithHooks.forEach((f) => {
      log({
        category: "components",
        check: "serverHooks",
        status: "fail",
        message: "Client hooks in server component",
        file: f.replace(ROOT + "/", ""),
      });
    });
  } else {
    log({ category: "components", check: "serverHooks", status: "pass", message: "No client hooks in server components" });
  }
}

// ============================================================================
// Caching Audit
// ============================================================================

function auditCaching() {
  console.log(`\n${COLORS.blue}═══ Caching Audit ═══${COLORS.reset}`);

  const srcDir = findSrcDir();
  const tsFiles = findFiles(srcDir, /\.tsx?$/, ["node_modules", ".next"]);

  // Check "use cache" directives
  const cacheDirectives = grepFiles(/"use cache"/, tsFiles);
  log({ category: "caching", check: "useCache", status: "info", message: `"use cache" directives: ${cacheDirectives.length}` });

  // Check revalidateTag usage
  const revalidateTags = grepFiles(/revalidateTag\(/, tsFiles);
  log({ category: "caching", check: "revalidateTag", status: "info", message: `revalidateTag calls: ${revalidateTags.length}` });

  // Check for force-dynamic overuse
  const forceDynamic = grepFiles(/dynamic\s*=\s*["']force-dynamic["']/, tsFiles);
  if (forceDynamic.length > 5) {
    log({ category: "caching", check: "forceDynamic", status: "warn", message: `${forceDynamic.length} force-dynamic exports - review if necessary` });
  } else if (forceDynamic.length > 0) {
    log({ category: "caching", check: "forceDynamic", status: "info", message: `${forceDynamic.length} force-dynamic exports` });
  } else {
    log({ category: "caching", check: "forceDynamic", status: "pass", message: "No force-dynamic exports (pages can be static)" });
  }

  // Check for revalidate = 0
  const revalidateZero = grepFiles(/revalidate\s*=\s*0/, tsFiles);
  if (revalidateZero.length > 0) {
    log({ category: "caching", check: "revalidateZero", status: "warn", message: `${revalidateZero.length} revalidate=0 (caching disabled)` });
  } else {
    log({ category: "caching", check: "revalidateZero", status: "pass", message: "No revalidate=0 (caching not disabled)" });
  }
}

// ============================================================================
// Code Quality Audit
// ============================================================================

function auditCodeQuality() {
  console.log(`\n${COLORS.blue}═══ Code Quality Audit ═══${COLORS.reset}`);

  // Check for large page components
  const appDir = findAppDir();
  const pageFiles = appDir ? findFiles(appDir, /page\.tsx$/, ["node_modules", ".next"]) : [];
  let largePages = 0;

  for (const file of pageFiles) {
    const content = readFileSync(file, "utf-8");
    const lines = content.split("\n").length;
    if (lines > 200) {
      log({
        category: "quality",
        check: "largePage",
        status: "warn",
        message: `Large page (${lines} lines) - consider splitting`,
        file: file.replace(ROOT + "/", ""),
      });
      largePages++;
    }
  }

  if (largePages === 0) {
    log({ category: "quality", check: "pageSize", status: "pass", message: "All pages under 200 lines" });
  }

  // Check for dynamic imports
  const srcDir = findSrcDir();
  const tsxFiles = findFiles(srcDir, /\.tsx$/, ["node_modules", ".next"]);
  const dynamicImports = grepFiles(/dynamic\(/, tsxFiles);
  log({ category: "quality", check: "dynamicImports", status: "info", message: `Dynamic imports: ${dynamicImports.length}` });
}

// ============================================================================
// AI Documentation Audit
// ============================================================================

function auditAIDocs() {
  console.log(`\n${COLORS.blue}═══ AI Documentation Audit ═══${COLORS.reset}`);

  const hasAgentsMd = existsSync(join(ROOT, "AGENTS.md"));
  const hasNextDocs = existsSync(join(ROOT, ".next-docs"));

  if (hasAgentsMd && hasNextDocs) {
    log({ category: "ai", check: "agentsMd", status: "pass", message: "AGENTS.md and .next-docs configured" });
  } else {
    if (!hasAgentsMd) {
      log({ category: "ai", check: "agentsMd", status: "fail", message: "AGENTS.md not found - run: bunx @next/codemod@canary agents-md" });
    }
    if (!hasNextDocs) {
      log({ category: "ai", check: "nextDocs", status: "fail", message: ".next-docs not found" });
    }
  }
}

// ============================================================================
// Main
// ============================================================================

function printSummary() {
  console.log(`\n${COLORS.blue}═══ Summary ═══${COLORS.reset}`);

  const counts = {
    pass: results.filter((r) => r.status === "pass").length,
    warn: results.filter((r) => r.status === "warn").length,
    fail: results.filter((r) => r.status === "fail").length,
    info: results.filter((r) => r.status === "info").length,
  };

  console.log(`  ${COLORS.green}✓ Passed: ${counts.pass}${COLORS.reset}`);
  console.log(`  ${COLORS.yellow}○ Warnings: ${counts.warn}${COLORS.reset}`);
  console.log(`  ${COLORS.red}✗ Failed: ${counts.fail}${COLORS.reset}`);
  console.log(`  ${COLORS.blue}ℹ Info: ${counts.info}${COLORS.reset}`);

  const score = Math.round((counts.pass / (counts.pass + counts.fail + counts.warn)) * 100) || 0;
  console.log(`\n  Score: ${score >= 80 ? COLORS.green : score >= 60 ? COLORS.yellow : COLORS.red}${score}/100${COLORS.reset}`);

  return counts.fail > 0 ? 1 : 0;
}

function main() {
  console.log(`${COLORS.blue}Next.js 16 Audit${COLORS.reset}`);
  console.log(`${COLORS.dim}Project: ${ROOT}${COLORS.reset}`);

  // Get versions
  try {
    const pkg = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf-8"));
    console.log(`${COLORS.dim}Next.js: ${pkg.dependencies?.next || pkg.devDependencies?.next || "unknown"}${COLORS.reset}`);
    console.log(`${COLORS.dim}React: ${pkg.dependencies?.react || "unknown"}${COLORS.reset}`);
  } catch {
    // ignore
  }

  auditConfig();
  auditImages();
  auditComponents();
  auditCaching();
  auditCodeQuality();
  auditAIDocs();

  const exitCode = printSummary();
  process.exit(exitCode);
}

main();
