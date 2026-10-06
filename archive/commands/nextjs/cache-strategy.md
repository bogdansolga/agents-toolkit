---
command: nextjs:cache-strategy
description: Analyze and improve caching strategy in a Next.js 16 project
---

## Description

Provides deep analysis and recommendations for caching in Next.js 16 projects:
- Identifies cacheable data and components
- Recommends optimal cache invalidation patterns
- Suggests "use cache" directive placement
- Analyzes current cache tag usage

## Parameters

- `path` (optional): Path to Next.js project. Defaults to current directory.
- `--implement` (optional): Automatically implement recommended caching
- `--focus` (optional): Focus area - `data`, `components`, `api`, `all` (default: `all`)

## Execution Steps

### 1. Current Caching Analysis

#### 1.1 Find Existing Cache Directives

```bash
echo "=== Existing Cache Usage ==="

# "use cache" directives
echo "Cache directives:"
grep -rn '"use cache"' --include="*.ts" --include="*.tsx" . 2>/dev/null

# revalidateTag calls
echo -e "\nrevalidateTag calls:"
grep -rn "revalidateTag" --include="*.ts" --include="*.tsx" . 2>/dev/null

# updateTag calls
echo -e "\nupdateTag calls:"
grep -rn "updateTag" --include="*.ts" --include="*.tsx" . 2>/dev/null

# refresh calls
echo -e "\nrefresh() calls:"
grep -rn "refresh()" --include="*.ts" --include="*.tsx" . 2>/dev/null
```

#### 1.2 Analyze Cache Tags

```bash
echo "=== Cache Tag Analysis ==="

# Extract all tag names
grep -rn "revalidateTag\|cacheTag" --include="*.ts" . 2>/dev/null | \
  grep -oE "['\"][a-zA-Z0-9-_]+['\"]" | sort | uniq -c | sort -rn
```

Build a tag dependency map:
- Which Server Actions invalidate which tags
- Which data fetches use which tags
- Identify orphaned tags (defined but never invalidated)

### 2. Identify Caching Opportunities

#### 2.1 Data Fetching Layer

```bash
echo "=== Data Fetching Analysis ==="

# Find all fetch calls
echo "External fetches:"
grep -rn "fetch(" --include="*.ts" --include="*.tsx" app/ lib/ 2>/dev/null | head -20

# Find database queries
echo -e "\nDatabase queries:"
grep -rn "db\.\|\.findMany\|\.findFirst\|\.findUnique\|\.query" \
  --include="*.ts" --include="*.tsx" . 2>/dev/null | head -20

# Find uncached queries in Server Components
echo -e "\nUncached in Server Components:"
for file in $(find app -name "page.tsx" -o -name "layout.tsx" 2>/dev/null); do
  if grep -q "db\.\|fetch(" "$file" && ! grep -q '"use cache"' "$file"; then
    echo "  $file"
  fi
done
```

#### 2.2 Component Layer

```bash
echo "=== Component Caching Analysis ==="

# Find expensive Server Components (with data fetching)
for file in $(find app components -name "*.tsx" 2>/dev/null); do
  if grep -q "async function\|async (" "$file"; then
    if grep -q "await\|fetch\|db\." "$file"; then
      if ! grep -q "'use client'\|\"use cache\"" "$file"; then
        LINES=$(wc -l < "$file")
        echo "Cacheable: $file ($LINES lines)"
      fi
    fi
  fi
done | head -20
```

#### 2.3 API Routes

```bash
echo "=== API Route Caching ==="

# Find GET routes that could be cached
for route in $(find app/api -name "route.ts" 2>/dev/null); do
  if grep -q "export.*GET" "$route"; then
    if ! grep -q "revalidate\|cache" "$route"; then
      echo "Cacheable GET: $route"
    fi
  fi
done
```

### 3. Generate Caching Recommendations

For each identified opportunity, provide:

```markdown
## Caching Recommendations

### High-Impact Opportunities

#### 1. Cache User Profile Data

**File:** `lib/services/user.service.ts`
**Current:**
```typescript
export async function getUserProfile(userId: string) {
  return db.user.findUnique({ where: { id: userId } });
}
```

**Recommended:**
```typescript
export async function getUserProfile(userId: string) {
  "use cache";
  cacheTag(`user-${userId}`);
  return db.user.findUnique({ where: { id: userId } });
}
```

**Invalidation:**
```typescript
// In updateUserProfile Server Action
'use server';
import { updateTag } from 'next/cache';

export async function updateUserProfile(userId: string, data: UserData) {
  await db.user.update({ where: { id: userId }, data });
  updateTag(`user-${userId}`); // Immediate refresh
}
```

**Impact:** Reduces database queries for repeated profile views

---

#### 2. Cache Dashboard Stats Component

**File:** `app/dashboard/components/Stats.tsx`
**Current:**
```typescript
export default async function Stats() {
  const stats = await fetchDashboardStats();
  return <div>...</div>;
}
```

**Recommended:**
```typescript
export default async function Stats() {
  "use cache";
  cacheLife('hours'); // Refresh every few hours
  const stats = await fetchDashboardStats();
  return <div>...</div>;
}
```

**Impact:** Dashboard loads faster, reduces API calls

---

### Cache Tag Strategy

Recommended tag naming convention:

| Entity | Tag Pattern | Example |
|--------|-------------|---------|
| User data | `user-{id}` | `user-123` |
| List data | `{entity}-list` | `posts-list` |
| Single item | `{entity}-{id}` | `post-456` |
| Global data | `{entity}-all` | `settings-all` |

### Cache Invalidation Matrix

| Action | Tags to Invalidate | Method |
|--------|-------------------|--------|
| Create post | `posts-list` | `revalidateTag('posts-list', 'max')` |
| Update post | `post-{id}`, `posts-list` | `updateTag('post-{id}')` |
| Delete post | `post-{id}`, `posts-list` | `revalidateTag('posts-list', 'max')` |
| Update user | `user-{id}` | `updateTag('user-{id}')` |

### Cache Lifetime Recommendations

| Data Type | cacheLife | Rationale |
|-----------|-----------|-----------|
| User profile | `'hours'` | Changes infrequently |
| Dashboard stats | `'hours'` | Aggregate data |
| Blog posts | `'max'` | Rarely changes |
| Real-time data | Don't cache | Use `refresh()` |
| Session-dependent | Don't cache | Use `connection()` |
```

### 4. Implementation Mode

If `--implement` flag:

For each recommendation:
1. Show the change
2. Ask for confirmation
3. Apply the edit
4. Verify build still works

```
Apply caching to getUserProfile? [y/N]
```

### 5. Cache Testing Guide

```markdown
## Testing Your Caching Strategy

### 1. Verify Cache Hits

```bash
# Enable verbose caching logs
NEXT_CACHE_DEBUG=1 bun run dev
```

Look for:
- `cache: HIT` - Data served from cache
- `cache: MISS` - Data fetched fresh
- `cache: STALE` - Serving stale while revalidating

### 2. Test Invalidation

```typescript
// In a test or debug route
import { revalidateTag } from 'next/cache';

export async function GET() {
  revalidateTag('posts-list', 'max');
  return Response.json({ revalidated: true });
}
```

### 3. Monitor Cache Size

```bash
# Check .next/cache size
du -sh .next/cache
```

### 4. Production Verification

In production, check response headers:
- `x-nextjs-cache: HIT` - Served from edge cache
- `x-nextjs-cache: STALE` - Stale-while-revalidate
- `x-nextjs-cache: MISS` - Fresh render
```

## Common Patterns

### Pattern 1: User-Scoped Cache

```typescript
async function getUserData(userId: string) {
  "use cache";
  cacheTag(`user-${userId}`);
  cacheLife('hours');
  return db.user.findUnique({ where: { id: userId } });
}
```

### Pattern 2: List with Item Invalidation

```typescript
async function getPosts() {
  "use cache";
  cacheTag('posts-list');
  cacheLife('max');
  return db.post.findMany();
}

async function getPost(id: string) {
  "use cache";
  cacheTag(`post-${id}`);
  cacheTag('posts-list'); // Also invalidate when list changes
  cacheLife('max');
  return db.post.findUnique({ where: { id } });
}
```

### Pattern 3: Time-Based Cache

```typescript
async function getAnalytics() {
  "use cache";
  cacheLife('hours'); // Refresh every few hours
  return aggregateAnalytics();
}
```

### Pattern 4: Read-Your-Writes

```typescript
'use server';

export async function updatePost(id: string, data: PostData) {
  await db.post.update({ where: { id }, data });
  updateTag(`post-${id}`); // User sees update immediately
}
```

## Success Criteria

- All caching opportunities identified
- Recommendations provided with code examples
- Cache tag strategy documented
- Invalidation patterns clear
- Testing guide included

## Example Usage

```bash
# Full caching analysis
/nextjs:cache-strategy

# Focus on data layer
/nextjs:cache-strategy --focus=data

# Auto-implement recommendations
/nextjs:cache-strategy --implement

# Analyze specific project
/nextjs:cache-strategy /path/to/project
```
