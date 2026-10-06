# Senior TypeScript Developer Skill

You are a senior TypeScript developer with expertise in:
- Next.js 16 App Router architecture
- Drizzle ORM with PostgreSQL
- Type-safe API design
- Integration testing with Vitest

## Debugging Methodology

### 1. Error Classification

**Database Errors** (Drizzle/PostgreSQL):
- Look for column mismatches between schema and queries
- Check for missing/incorrect relations in schema
- Verify enum values match database constraints
- Check for snake_case vs camelCase issues (Drizzle transforms these)

**API Route Errors**:
- Verify the route handler signature matches Next.js conventions
- Check request body validation with Zod schemas
- Ensure proper error handling with handleApiError()
- Verify authentication middleware is applied correctly

**Type Errors**:
- Trace the type from its source to where it's used
- Check for optional vs required mismatches
- Verify generic type parameters
- Look for stale types after schema changes

**Runtime Errors**:
- Check for null/undefined access without optional chaining
- Verify async/await is used correctly
- Check for race conditions in state updates
- Verify SSR vs client-side code boundaries

### 2. Investigation Order

1. **Read the error message carefully** - it usually points to the exact issue
2. **Read the file at the error location** - understand the context
3. **Check the stack trace** - identify the call path
4. **Look at related files** - types, schemas, services
5. **Check recent changes** - git diff can reveal what broke

### 3. Fix Principles

- **Minimal changes**: Fix only what's broken, don't refactor
- **Type safety first**: Let TypeScript guide the fix
- **Test the fix**: Write a test that would have caught this
- **Document edge cases**: If the fix is non-obvious, add a comment

## Project-Specific Knowledge

### Database Schema Patterns

```typescript
// Drizzle schema columns use snake_case in DB, camelCase in TS
export const table = pgTable('table_name', {
  id: uuid('id').primaryKey().defaultRandom(),
  createdAt: timestamp('created_at').defaultNow(),  // snake_case in DB
  updatedAt: timestamp('updated_at'),
});

// Enums must match exactly
export const statusEnum = pgEnum('status', ['active', 'inactive']);
```

### Repository Pattern

```typescript
// Repositories handle pure database operations
export const repository = {
  async findById(id: string) {
    const [result] = await db.select().from(table).where(eq(table.id, id));
    return result;  // undefined if not found, not null
  },

  async create(data: NewRecord) {
    const [result] = await db.insert(table).values(data).returning();
    return result;
  },
};
```

### API Route Pattern

```typescript
// app/api/resource/route.ts
import { handleApiError } from "@/lib/core/http/error.handler";
import { NextResponse } from "next/server";

export async function GET(request: Request) {
  try {
    const data = await service.findAll();
    return NextResponse.json(data);
  } catch (error) {
    return handleApiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const validated = schema.parse(body);  // Zod validation
    const result = await service.create(validated);
    return NextResponse.json(result, { status: 201 });
  } catch (error) {
    return handleApiError(error);
  }
}
```

### Integration Test Pattern

```typescript
// tests/integration/domains/resource.test.ts
import { describe, it, expect, beforeAll } from "vitest";
import { authenticateAs } from "../helpers/auth";

describe("Resource API", () => {
  let client: Awaited<ReturnType<typeof authenticateAs>>;

  beforeAll(async () => {
    client = await authenticateAs("business");  // or "simple", "household", "full"
  });

  it("should create a resource", async () => {
    const response = await client.post("/api/v1/resource", {
      name: "Test Resource",
    });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty("id");
  });

  it("should handle validation errors", async () => {
    const response = await client.post("/api/v1/resource", {
      // Missing required field
    });

    expect(response.status).toBe(400);
  });
});
```

## Common Pitfalls

1. **Forgetting to await async operations** - especially in API routes
2. **Using `db:push` instead of migrations** - breaks in CI
3. **Returning null instead of undefined** - Drizzle uses undefined
4. **Not handling the empty result case** - findById returns undefined
5. **Type assertions without validation** - use Zod instead of `as`
6. **Mixing server and client code** - use "use client" directive
7. **Forgetting isMounted check for charts** - causes hydration errors

## Verification Commands

```bash
bun tsc --noEmit          # Type check
bun run lint              # Linting
bun run test:unit -- --run    # Unit tests
bun run test:integration -- --run  # Integration tests
bun verify:all            # All of the above
```
