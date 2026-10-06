---
command: nextjs:optimize
description: Apply Next.js 16 optimizations to a project - React Compiler, caching, Turbopack
---

## Description

Applies recommended Next.js 16 optimizations to a project:
- Enables React Compiler for automatic memoization
- Configures cacheComponents for PPR
- Sets up Turbopack filesystem cache
- Installs required dependencies
- Updates configuration

## Parameters

- `path` (optional): Path to Next.js project. Defaults to current directory.
- `--dry-run` (optional): Show what would change without making changes
- `--skip-deps` (optional): Skip dependency installation

## Execution Steps

### 1. Analyze Current Configuration

```bash
echo "=== Current Configuration ==="
cat next.config.* 2>/dev/null
```

Read `next.config.ts` to understand current settings.

### 2. Check Dependencies

```bash
echo "=== Checking Dependencies ==="

# Check for React Compiler plugin
if grep -q "babel-plugin-react-compiler" package.json; then
  echo "✓ babel-plugin-react-compiler installed"
else
  echo "✗ babel-plugin-react-compiler not installed"
  NEED_DEPS=true
fi
```

### 3. Install Required Dependencies

If `--skip-deps` not set and dependencies needed:

```bash
bun add -D babel-plugin-react-compiler@latest
```

### 4. Update next.config.ts

Read current config and apply optimizations:

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // ... existing config ...

  // React Compiler - automatic memoization
  reactCompiler: true,

  // Cache Components - enables PPR and "use cache" directive
  cacheComponents: true,

  // Turbopack filesystem cache for faster dev restarts
  experimental: {
    // ... existing experimental ...
    turbopackFileSystemCacheForDev: true,
  },
};

export default nextConfig;
```

**Rules:**
- Preserve all existing configuration
- Add new options without overwriting
- Merge experimental options properly
- Keep any custom settings

### 5. Verify TypeScript Configuration

Check `tsconfig.json` for React Compiler compatibility:

```json
{
  "compilerOptions": {
    "jsx": "preserve",
    "strict": true
  }
}
```

### 6. Create/Update .env.local (if needed)

For any environment-specific optimizations:

```bash
# Check if TURBOPACK_DEV_CACHE_DIR is useful
# (usually not needed, Turbopack handles this)
```

### 7. Verify Build

```bash
echo "=== Verifying Build ==="
bun run build
```

If build fails:
1. Check for React Compiler errors (usually strict mode violations)
2. Provide specific fix suggestions
3. Option to disable specific optimizations

### 8. Report Changes

```markdown
## Optimizations Applied

### Configuration Changes

| Setting | Before | After | Benefit |
|---------|--------|-------|---------|
| reactCompiler | ❌ | ✅ | Automatic memoization, reduced re-renders |
| cacheComponents | ❌ | ✅ | PPR support, "use cache" directive |
| turbopackFileSystemCacheForDev | ❌ | ✅ | Faster dev server restarts |

### Dependencies Added

- `babel-plugin-react-compiler@{version}`

### Expected Benefits

1. **React Compiler**
   - Automatic React.memo() equivalent
   - Automatic useMemo/useCallback
   - Smaller bundle (removes manual memoization)

2. **Cache Components**
   - Partial Pre-Rendering (PPR)
   - Granular caching with "use cache"
   - Faster page loads

3. **Turbopack FS Cache**
   - Persistent compilation cache
   - Faster dev server cold starts
   - Reduced memory usage

### Next Steps

1. Run `bun run dev` to verify development works
2. Consider adding "use cache" to expensive components
3. Run `/nextjs:audit` to find more optimization opportunities
```

## Handling Common Issues

### React Compiler Errors

If React Compiler fails:

```
Error: React Compiler found issues in your code
```

**Common fixes:**
1. Ensure components follow Rules of React
2. Check for mutating props or state directly
3. Look for non-idempotent renders

**Disable for specific files:**
```typescript
// eslint-disable-next-line react-compiler/react-compiler
function LegacyComponent() { ... }
```

### cacheComponents with Dynamic Routes

If using heavy dynamic routes:

```typescript
// For truly dynamic pages, opt out:
export const dynamic = 'force-dynamic';
```

### Build Failures

If build fails after optimization:

1. Check error message for specific file
2. Temporarily disable optimization:
   ```typescript
   reactCompiler: false, // Disable to isolate issue
   ```
3. Fix underlying issue
4. Re-enable optimization

## Success Criteria

- next.config.ts updated with optimizations
- Dependencies installed
- Build succeeds
- No runtime errors

## Example Usage

```bash
# Apply all optimizations
/nextjs:optimize

# Preview changes without applying
/nextjs:optimize --dry-run

# Skip dependency installation
/nextjs:optimize --skip-deps

# Optimize specific project
/nextjs:optimize /path/to/project
```

## Rollback

If needed, revert via git:

```bash
git checkout next.config.ts package.json bun.lockb
bun install
```
