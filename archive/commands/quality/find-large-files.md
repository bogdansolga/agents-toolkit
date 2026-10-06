---
command: quality:find-large-files
description: Find top 5 largest files and recommend how to split them
---

## Description

Searches the codebase for the top 5 largest files (by line count), displays them with details, and provides actionable recommendations on how to split them for better maintainability.

## Execution Steps

1. **Find Large Files**
   - Search for `.ts`, `.tsx`, `.js`, `.jsx` files in `src/`
   - Exclude `node_modules`, `.next`, `dist`, and generated files
   - Sort by line count descending
   - Select top 5 largest files

2. **Analyze Each File**
   - Count total lines
   - Identify file type (component, service, schema, API route, etc.)
   - Identify major sections (exports, functions, classes, etc.)
   - Note any code smells (too many responsibilities, mixed concerns)

3. **Generate Recommendations**
   For each large file, provide:
   - Current line count and file type
   - Identified concerns/responsibilities
   - Specific splitting recommendations
   - Suggested new file names

4. **Display Results**
   Present findings in a clear, actionable format

## Output Format

```markdown
# Top 5 Largest Files Analysis

## 1. {filename} ({line_count} lines)

**Type:** {component|service|schema|utility|etc.}

**Current Structure:**
- {description of major sections}

**Recommendations:**
- [ ] {specific action 1}
- [ ] {specific action 2}

**Suggested Split:**
- `{new-file-1.ts}` - {responsibility}
- `{new-file-2.ts}` - {responsibility}

---

## 2. {filename} ({line_count} lines)
...
```

## Splitting Guidelines

### Components (`.tsx`)
- Extract hooks into separate `use{Name}.ts` files
- Split sub-components into their own files
- Move types to `{component}.types.ts`
- Extract constants to `{component}.constants.ts`

### Services
- Split by domain responsibility
- Extract shared utilities
- Separate data transformation logic
- Create dedicated error handling modules

### Schema Files
- Split by entity/table groupings
- Extract enums to dedicated file
- Separate relations from table definitions

### API Routes
- Extract request/response types
- Move business logic to services
- Create dedicated validation schemas

## Thresholds

| File Type | Ideal Max Lines | Warning | Critical |
|-----------|-----------------|---------|----------|
| Component | 150 | 250 | 400+ |
| Service | 200 | 350 | 500+ |
| Schema | 300 | 500 | 800+ |
| Utility | 100 | 200 | 300+ |

## Notes

- Focus on actionable recommendations
- Consider existing project patterns when suggesting splits
- Prioritize recommendations by impact and effort
- Line count includes comments and whitespace
