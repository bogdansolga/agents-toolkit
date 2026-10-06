---
command: nextjs:setup-agents
description: Set up AGENTS.md with version-matched Next.js documentation for AI-assisted development
---

## Description

Installs the AGENTS.md documentation system that provides AI agents with persistent, version-matched Next.js documentation. This approach achieved **100% pass rate** in Vercel's agent evaluations (vs 53% baseline).

The system works by:
1. Detecting your Next.js version
2. Downloading compressed, version-matched documentation to `.next-docs/`
3. Creating an `AGENTS.md` index file that's loaded into agent context

## Prerequisites

- Must be run in a Next.js project directory
- Requires `bun` or `bunx` available in PATH

## Parameters

- `path` (optional): Path to Next.js project. Defaults to current directory.
- `--version` (optional): Specific Next.js version to use (e.g., `16.0.0`)

## Execution Steps

### 1. Verify Next.js Project

```bash
# Check for next.config.ts or next.config.js
ls next.config.* 2>/dev/null || echo "ERROR: Not a Next.js project"

# Get current Next.js version
cat package.json | grep '"next":' | head -1
```

If not in a Next.js project, report error and exit.

### 2. Copy Documentation from Claude Config

Copy the pre-downloaded Next.js documentation:

```bash
# Copy from claude-config
cp -r ~/.claude-config/next-docs ./.next-docs

# Create AGENTS.md index
cat > AGENTS.md << 'EOF'
[Next.js Docs Index]|root: ./.next-docs
|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
EOF
```

**Alternative: Run the Codemod** (downloads fresh docs):

```bash
bunx @next/codemod@canary agents-md
```

This is interactive and will:
- Detect your Next.js version (or prompt to select)
- Download version-matched documentation
- Create the `.next-docs/` directory
- Generate `AGENTS.md` with the documentation index

### 3. Verify Installation

After the codemod completes:

```bash
# Verify .next-docs exists
ls -la .next-docs/

# Verify AGENTS.md exists
cat AGENTS.md | head -20

# Check documentation index
wc -l .next-docs/*.md 2>/dev/null || ls .next-docs/
```

### 4. Update .gitignore (if needed)

Check if `.next-docs/` should be committed or ignored:

```bash
# Check if already in .gitignore
grep -q ".next-docs" .gitignore 2>/dev/null && echo "Already in .gitignore"

# Recommend: Commit it for consistency across team
# The docs are ~8KB compressed and version-matched
```

**Recommendation**: Commit `.next-docs/` to version control so all team members and CI have the same documentation.

### 5. Verify AGENTS.md Content

The `AGENTS.md` file should contain:

```markdown
[Next.js Docs Index]|root: ./.next-docs
|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
```

If this structure is missing, the setup may have failed.

## Success Criteria

- `.next-docs/` directory exists with documentation files
- `AGENTS.md` file exists with documentation index
- Documentation version matches project's Next.js version
- No errors during codemod execution

## Post-Setup Instructions

After setup, inform the user:

```
AGENTS.md setup complete.

How it works:
- AI agents now have persistent access to Next.js ${version} documentation
- Documentation is retrieved from .next-docs/ instead of training data
- This eliminates outdated API usage and improves accuracy

Files created:
- AGENTS.md (documentation index)
- .next-docs/ (compressed documentation)

Recommendation: Commit both to version control for team consistency.
```

## Troubleshooting

### Codemod Fails to Detect Version

```bash
# Manually specify version
bunx @next/codemod@canary agents-md --version 16.0.0
```

### Permission Errors

```bash
# Check directory permissions
ls -la .
# May need to fix ownership if in Docker volume
```

### Network Errors

The codemod downloads documentation from Vercel's CDN. If offline:
- Check network connectivity
- Try again later
- Consider copying `.next-docs/` from another project with same version

## Example Usage

```bash
# In current directory
/nextjs:setup-agents

# In specific project
/nextjs:setup-agents /path/to/nextjs-project

# Force specific version
/nextjs:setup-agents --version 16.0.0
```

## Why This Matters

Without AGENTS.md, AI agents:
- Rely on potentially outdated training data
- May suggest deprecated APIs
- Miss new features like `"use cache"` directive
- Have 53% accuracy on framework-specific tasks

With AGENTS.md:
- Documentation is always version-matched
- New APIs are correctly used
- 100% accuracy on framework tasks
- No hallucinated API usage
