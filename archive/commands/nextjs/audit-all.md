---
command: nextjs:audit-all
description: Audit all Next.js projects in a directory for optimization opportunities
---

## Description

Audits all Next.js projects in a directory tree, generating a consolidated report of:
- Configuration status across projects
- Common optimization opportunities
- AGENTS.md setup status
- Caching strategy analysis

Designed for maintaining multiple Next.js projects.

## Parameters

- `path` (required): Root directory containing Next.js projects
- `--json` (optional): Output in JSON format
- `--skip` (optional): Comma-separated project names to skip
- `--focus` (optional): Focus area - `config`, `caching`, `performance`, `all` (default: `all`)

## Execution Steps

### 1. Discover Projects

```bash
PROJECTS_ROOT="${1:-/Volumes/NVMe/Development/IdeaProjects/personal}"

echo "=== Discovering Next.js Projects ==="

# Find all next.config.* files
find "$PROJECTS_ROOT" -name "next.config.*" -type f \
  ! -path "*/node_modules/*" \
  ! -path "*/.next/*" \
  ! -path "*/standalone/*" \
  ! -path "*/.template*" \
  2>/dev/null | while read config; do
    PROJECT_DIR=$(dirname "$config")
    PROJECT_NAME=$(basename "$PROJECT_DIR")
    echo "$PROJECT_NAME: $PROJECT_DIR"
done
```

### 2. Quick Audit Each Project

For each project, gather key metrics:

```bash
audit_project() {
  local dir="$1"
  local name=$(basename "$dir")

  cd "$dir"

  # Version
  NEXT_VERSION=$(cat package.json 2>/dev/null | jq -r '.dependencies.next // .devDependencies.next' | sed 's/[\^~]//g')

  # Config checks
  REACT_COMPILER=$(grep -q "reactCompiler.*true" next.config.* 2>/dev/null && echo "✓" || echo "✗")
  CACHE_COMPONENTS=$(grep -q "cacheComponents.*true" next.config.* 2>/dev/null && echo "✓" || echo "✗")
  TURBOPACK_CACHE=$(grep -q "turbopackFileSystemCacheForDev.*true" next.config.* 2>/dev/null && echo "○" || echo "✗")

  # AGENTS.md
  AGENTS_MD=$([ -f "AGENTS.md" ] && [ -d ".next-docs" ] && echo "✓" || echo "✗")

  # Cache usage
  USE_CACHE_COUNT=$(grep -r '"use cache"' --include="*.ts" --include="*.tsx" . 2>/dev/null | wc -l | tr -d ' ')

  # Client components
  CLIENT_COUNT=$(grep -rl "'use client'" --include="*.tsx" . 2>/dev/null | wc -l | tr -d ' ')

  echo "$name|$NEXT_VERSION|$REACT_COMPILER|$CACHE_COMPONENTS|$TURBOPACK_CACHE|$AGENTS_MD|$USE_CACHE_COUNT|$CLIENT_COUNT"
}
```

### 3. Generate Consolidated Report

```markdown
## Next.js Projects Audit Report

**Directory:** {root_path}
**Date:** {date}
**Projects Found:** {count}

---

### Configuration Summary

| Project | Version | React Compiler | cacheComponents | Turbopack Cache | AGENTS.md |
|---------|---------|----------------|-----------------|-----------------|-----------|
| training-manager | 16.0.4 | ✓ | ✓ | ○ | ✓ |
| files-manager | 16.0.4 | ✓ | ✗ | ✗ | ✗ |
| apps-manager | 16.0.2 | ✗ | ✗ | ✗ | ✗ |
| life-manager | 16.1.0 | ✓ | ✓ | ✓ | ✓ |
| car-manager | 16.0.4 | ✓ | ✓ | ○ | ✗ |
| finances-manager | 16.0.4 | ✓ | ✓ | ✓ | ✓ |

**Legend:** ✓ = Enabled | ✗ = Not enabled | ○ = Optional/Not set

---

### Optimization Scores

| Project | Config Score | Caching Score | Overall |
|---------|--------------|---------------|---------|
| life-manager | 10/10 | 8/10 | A |
| finances-manager | 10/10 | 7/10 | A |
| training-manager | 8/10 | 5/10 | B |
| car-manager | 7/10 | 4/10 | B |
| files-manager | 5/10 | 3/10 | C |
| apps-manager | 3/10 | 2/10 | D |

---

### Caching Analysis

| Project | "use cache" | revalidateTag | Client Components |
|---------|-------------|---------------|-------------------|
| finances-manager | 15 | 8 | 12 |
| life-manager | 12 | 6 | 10 |
| training-manager | 5 | 3 | 18 |
| files-manager | 0 | 0 | 25 |
| ... | ... | ... | ... |

**Observations:**
- `files-manager` has many client components but no caching - review for optimization
- `training-manager` could benefit from more aggressive caching

---

### AGENTS.md Status

**Configured:** {N} projects
**Not Configured:** {N} projects

Projects needing AGENTS.md setup:
1. files-manager
2. apps-manager
3. car-manager

**Setup command:**
```bash
# Quick setup from claude-config
cd /path/to/project && cp -r ~/.claude-config/next-docs ./.next-docs

# Or download fresh via codemod
cd /path/to/project && bunx @next/codemod@canary agents-md
```

---

### Priority Actions

#### High Priority (Do First)

1. **apps-manager** - Missing all optimizations
   ```bash
   /nextjs:optimize /Volumes/NVMe/Development/IdeaProjects/personal/apps-manager
   ```

2. **files-manager** - No caching strategy
   ```bash
   /nextjs:cache-strategy /Volumes/NVMe/Development/IdeaProjects/personal/files-manager
   ```

#### Medium Priority

3. **car-manager** - Missing AGENTS.md
4. **training-manager** - Could improve caching

#### Low Priority

5. Enable Turbopack FS cache where not set (optional but beneficial)

---

### Batch Commands

```bash
# Setup AGENTS.md for all projects missing it
for project in files-manager apps-manager car-manager; do
  cd "/Volumes/NVMe/Development/IdeaProjects/personal/$project"
  bunx @next/codemod@canary agents-md
done

# Audit specific project in detail
/nextjs:audit /Volumes/NVMe/Development/IdeaProjects/personal/files-manager

# Optimize specific project
/nextjs:optimize /Volumes/NVMe/Development/IdeaProjects/personal/apps-manager
```

---

### Version Summary

| Version | Projects |
|---------|----------|
| 16.1.x | 1 |
| 16.0.x | 5 |

All projects on Next.js 16 - no migrations needed.
```

### 4. Interactive Follow-up

```
What would you like to do?

1. Run detailed audit on lowest-scoring project
2. Setup AGENTS.md for all missing projects
3. Apply optimizations to specific project
4. View caching recommendations for specific project
5. Export report as JSON
6. Exit
```

## Success Criteria

- All projects discovered and audited
- Configuration status clear for each project
- Priorities identified
- Actionable next steps provided

## Example Usage

```bash
# Audit all personal projects
/nextjs:audit-all /Volumes/NVMe/Development/IdeaProjects/personal

# Focus on caching only
/nextjs:audit-all /Volumes/NVMe/Development/IdeaProjects/personal --focus=caching

# Skip certain projects
/nextjs:audit-all /Volumes/NVMe/Development/IdeaProjects/personal --skip=scaffolding-tests

# JSON output for scripting
/nextjs:audit-all /Volumes/NVMe/Development/IdeaProjects/personal --json
```

## Notes for Personal Projects

Known projects in `/Volumes/NVMe/Development/IdeaProjects/personal/`:

**Main Applications:**
- training-manager
- files-manager
- apps-manager
- life-manager
- car-manager
- finances-manager
- learnmicroservices-clone
- personal-apps-monitor

**Skip by default:**
- scaffolding-tests (templates, not apps)
- Any `.next/standalone` directories
- Template files (`*.template`)
