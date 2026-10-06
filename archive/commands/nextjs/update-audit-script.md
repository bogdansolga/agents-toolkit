---
command: nextjs:update-audit-script
description: Update and refine the portable Next.js audit script based on new findings or requirements
---

## Description

Updates the portable Next.js 16 audit script located at:
`~/.claude-config/scripts/nextjs-audit.ts`

This script is the canonical implementation for auditing Next.js projects across the personal directory.

## When to Use

- Adding new audit checks (e.g., new Next.js features, security patterns)
- Improving detection accuracy (reducing false positives/negatives)
- Adding new output formats (JSON, markdown report)
- Fixing bugs or edge cases discovered in other projects
- Updating for new Next.js versions

## Script Location

```
~/.claude-config/scripts/nextjs-audit.ts
```

## Current Capabilities

The script audits:
1. **Configuration** - reactCompiler, cacheComponents, turbopackFileSystemCacheForDev, image TTL, standalone output
2. **Images** - Unoptimized `<img>` tags, next/image usage, priority prop on LCP images
3. **Component Boundaries** - Client vs server components, unnecessary "use client" directives, client hooks in server components
4. **Caching** - "use cache" directives, revalidateTag usage, force-dynamic overuse, revalidate=0
5. **Code Quality** - Large pages (>200 lines), dynamic imports
6. **AI Documentation** - AGENTS.md and .next-docs presence

## Portability Features

The script works across different project structures:
- `findConfigFile()` - Supports next.config.ts, .js, .mjs
- `findAppDir()` - Supports src/app and root app/
- `findSrcDir()` - Handles projects with/without src directory

## Execution Steps

### 1. Read Current Script

```bash
cat ~/.claude-config/scripts/nextjs-audit.ts
```

### 2. Understand the Request

Determine what changes are needed:
- New audit check category?
- Refinement to existing check?
- Bug fix for edge case?
- Output format change?

### 3. Make Changes

Edit the script maintaining:
- Portability (use findConfigFile, findAppDir, findSrcDir helpers)
- Consistent output format (pass/warn/fail/info with icons)
- Clear messages with file locations
- No external dependencies beyond Node.js/Bun built-ins

### 4. Test on Multiple Projects

```bash
# Test on training-manager
cd /Volumes/NVMe/Development/IdeaProjects/personal/training-manager
bun run ~/.claude-config/scripts/nextjs-audit.ts

# Test on finances-manager (complex structure)
cd /Volumes/NVMe/Development/IdeaProjects/personal/finances-manager
bun run ~/.claude-config/scripts/nextjs-audit.ts

# Test on learnmicroservices-clone
cd /Volumes/NVMe/Development/IdeaProjects/personal/learnmicroservices-clone
bun run ~/.claude-config/scripts/nextjs-audit.ts
```

### 5. Commit Changes

```bash
cd ~/.claude-config
git add scripts/nextjs-audit.ts
git commit -m "Update nextjs-audit.ts: <description of changes>"
```

## Adding New Audit Checks

Template for new check:

```typescript
function auditNewCategory() {
  console.log(`\n${COLORS.blue}═══ New Category Audit ═══${COLORS.reset}`);

  const srcDir = findSrcDir();
  const appDir = findAppDir();

  // Your check logic here

  if (condition) {
    log({
      category: "newcategory",
      check: "checkName",
      status: "pass",
      message: "Check passed"
    });
  } else {
    log({
      category: "newcategory",
      check: "checkName",
      status: "fail",
      message: "Check failed - action to take",
      file: "relative/path.tsx",
      line: 42
    });
  }
}

// Add to main():
auditNewCategory();
```

## Example Improvements

1. **Add security check for exposed API keys**
2. **Check for proper error boundaries**
3. **Validate metadata exports on pages**
4. **Check for proper loading.tsx usage**
5. **Validate route segment configs**
6. **Add JSON output mode with --json flag**

## Related Commands

- `/nextjs:audit` - Run the audit (uses this script or manual steps)
- `/nextjs:audit-all` - Audit all projects in a directory
- `/nextjs:optimize` - Apply optimizations based on audit findings
