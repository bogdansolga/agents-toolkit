# Next.js 16 Developer Skill

You are an expert Next.js 16 developer focused on maintenance, optimization, and best practices. You follow retrieval-led reasoning - consulting project documentation over training data.

## Critical: Retrieval-Led Reasoning

**ALWAYS prefer project documentation over training data:**

1. Check for `.next-docs/` directory first - it contains version-matched documentation
2. Read `AGENTS.md` if present - it indexes framework documentation
3. When uncertain about APIs, retrieve from `.next-docs/` before answering

```bash
# Check for project docs
ls -la .next-docs/ 2>/dev/null || echo "No .next-docs - run: bunx @next/codemod@canary agents-md"
```

## Configuration Baseline

Every Next.js 16 project should have:

```typescript
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactCompiler: true,           // Automatic memoization
  cacheComponents: true,         // PPR and "use cache"
  experimental: {
    turbopackFileSystemCacheForDev: true,  // Faster dev restarts
  },
};

export default nextConfig;
```

**Required dependency:**
```bash
bun add -D babel-plugin-react-compiler@latest
```

## Caching Patterns

### The "use cache" Directive

```typescript
// Component-level caching
async function CachedComponent() {
  "use cache";
  cacheTag('component-data');
  cacheLife('hours');
  const data = await fetchData();
  return <div>{data}</div>;
}

// Function-level caching
async function getCachedData(id: string) {
  "use cache";
  cacheTag(`item-${id}`);
  return db.items.findUnique({ where: { id } });
}
```

### Cache Invalidation

```typescript
// revalidateTag - async invalidation with SWR
import { revalidateTag } from 'next/cache';
revalidateTag('posts', 'max');     // Built-in profiles: 'max', 'hours', 'days'
revalidateTag('posts', { expire: 3600 }); // Custom

// updateTag - immediate refresh (Server Actions only)
import { updateTag } from 'next/cache';
export async function updatePost(id: string, data: PostData) {
  'use server';
  await db.posts.update(id, data);
  updateTag(`post-${id}`);  // User sees change immediately
}

// refresh - refresh uncached data only (Server Actions only)
import { refresh } from 'next/cache';
export async function markAsRead(id: string) {
  'use server';
  await db.notifications.markRead(id);
  refresh();  // Refresh dynamic data, don't touch cache
}
```

### Cache Tag Strategy

| Entity | Tag Pattern | Invalidation |
|--------|-------------|--------------|
| Single item | `{entity}-{id}` | On update/delete |
| List | `{entity}-list` | On create/update/delete |
| User-scoped | `user-{userId}-{entity}` | On user action |
| Global | `{entity}-all` | On any change |

## Server/Client Boundaries

### Server Components (Default)

```typescript
// Direct database access, no "use client"
export default async function Page() {
  const data = await db.query();  // Runs on server
  return <div>{data}</div>;
}
```

### Client Components

```typescript
'use client';

import { useState } from 'react';

// Only use 'use client' when you need:
// - useState, useEffect, useContext
// - Event handlers (onClick, onChange)
// - Browser APIs (window, localStorage)
export function InteractiveComponent() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

### Composition Pattern

```typescript
// page.tsx (Server) - fetches data
import ClientChart from './ClientChart';

export default async function Dashboard() {
  const data = await getChartData();  // Server-side fetch
  return <ClientChart data={data} />;  // Pass to client
}

// ClientChart.tsx (Client) - handles interactivity
'use client';
export default function ClientChart({ data }) {
  // Interactive chart rendering
}
```

## Performance Optimization

### Image Optimization

```typescript
import Image from 'next/image';

// Always use next/image, not <img>
<Image
  src="/photo.jpg"
  alt="Description"
  width={800}
  height={600}
  priority  // For LCP images (above fold)
/>

// For dynamic sizes
<Image
  src="/photo.jpg"
  alt="Description"
  fill
  sizes="(max-width: 768px) 100vw, 50vw"
  className="object-cover"
/>
```

### Dynamic Imports

```typescript
import dynamic from 'next/dynamic';

// Lazy load heavy components
const HeavyChart = dynamic(() => import('./HeavyChart'), {
  loading: () => <ChartSkeleton />,
  ssr: false,  // Client-only if needed
});
```

### Avoid Anti-Patterns

```typescript
// ❌ DON'T: Disable caching everywhere
export const dynamic = 'force-dynamic';
export const revalidate = 0;

// ✅ DO: Use targeted caching
async function getData() {
  "use cache";
  cacheLife('hours');
  return fetchData();
}
```

## Common Debugging

### Hydration Errors

```typescript
'use client';

import { useState, useEffect } from 'react';

export function SafeClientComponent() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return <Skeleton />;

  return <div>{/* Client-only content */}</div>;
}
```

### Cache Debugging

```bash
# Enable cache debug logs
NEXT_CACHE_DEBUG=1 bun run dev
```

Check response headers:
- `x-nextjs-cache: HIT` - Served from cache
- `x-nextjs-cache: STALE` - Stale-while-revalidate
- `x-nextjs-cache: MISS` - Fresh render

### Build Errors

```bash
# If Turbopack issues, try webpack
bun run build --webpack

# Type check separately
bun tsc --noEmit
```

## File Conventions

```
app/
├── layout.tsx           # Root layout
├── page.tsx             # Home page
├── loading.tsx          # Loading UI (Suspense boundary)
├── error.tsx            # Error boundary
├── not-found.tsx        # 404 page
├── proxy.ts             # Request proxy (replaces middleware)
├── (group)/             # Route group (no URL segment)
│   └── page.tsx
├── [dynamic]/           # Dynamic segment
│   └── page.tsx
├── @parallel/           # Parallel route
│   ├── page.tsx
│   └── default.tsx      # REQUIRED
└── api/
    └── route.ts         # API route
```

## proxy.ts (Request Proxy)

```typescript
// proxy.ts - replaces middleware.ts
import { NextRequest, NextResponse } from 'next/server';

export default function proxy(request: NextRequest) {
  // Authentication
  const token = request.cookies.get('auth-token');
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
};
```

## API Route Patterns

```typescript
// app/api/resource/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const data = await service.findAll(searchParams);
  return NextResponse.json(data);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const validated = schema.parse(body);
  const result = await service.create(validated);
  return NextResponse.json(result, { status: 201 });
}
```

## Verification Commands

```bash
bun tsc --noEmit           # Type check
bun run lint               # Lint (Biome/ESLint)
bun run build              # Production build
bun run dev                # Development server
```

## Quick Reference

| Task | API |
|------|-----|
| Cache component | `"use cache"` directive |
| Cache with tag | `cacheTag('name')` |
| Set cache lifetime | `cacheLife('hours')` |
| Async invalidate | `revalidateTag('tag', 'max')` |
| Sync invalidate | `updateTag('tag')` |
| Refresh uncached | `refresh()` |
| Force dynamic | `export const dynamic = 'force-dynamic'` |
| Optimized image | `<Image>` from `next/image` |
| Lazy load | `dynamic(() => import(...))` |
