# Create a Marp Presentation

Create a styled Marp slide deck from markdown content, exported as individual PDF files per section.

## Arguments

- `$ARGUMENTS` — Path to the working directory containing markdown content files (e.g., `00-agenda.md`, `01-topic.md`, etc.), OR a description of what to create.

## Workflow

### 1. Understand the content

- If markdown content files already exist in the directory, read them all
- If only a description is given, ask clarifying questions first (audience, language, duration, key topics)
- Identify distinct sections (numbered `00-`, `01-`, `02-`, etc.)

### 2. Create the combined Marp slides file

Create a single `slides.md` file with all sections combined. Use this CSS style block as the standard theme:

```markdown
---
marp: true
theme: default
paginate: true
footer: '© [Author Name]'
---

<style>
  :root {
    --blue: #4285f4;
    --dark-gray: #444;
    --mid-gray: #666;
    --light-gray: #f8f9fa;
  }

  section {
    font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
    color: var(--dark-gray);
    padding: 40px 60px 60px;
  }

  section.lead {
    background: var(--blue);
    color: white;
    justify-content: center;
    padding: 60px 80px;
  }
  section.lead h1 {
    font-size: 2.6em;
    font-weight: 500;
    color: white;
    border: none;
    margin-bottom: 0.1em;
  }
  section.lead h2 {
    font-size: 1.3em;
    font-weight: 300;
    color: rgba(255,255,255,0.85);
    border: none;
    margin-top: 0;
  }
  section.lead footer { color: rgba(255,255,255,0.7); }
  section.lead::after { color: rgba(255,255,255,0.5); }

  h1 {
    font-size: 1.5em;
    color: white;
    background: var(--blue);
    margin: -40px -60px 30px;
    padding: 12px 60px;
    font-weight: 500;
    border: none;
  }
  h2 {
    font-size: 1.15em;
    color: var(--blue);
    border: none;
    margin-top: 0.6em;
    margin-bottom: 0.3em;
    font-weight: 600;
  }

  li { color: var(--mid-gray); font-size: 0.85em; line-height: 1.5; margin-bottom: 0.15em; }
  li li { font-size: 0.95em; }
  p { color: var(--mid-gray); font-size: 0.85em; line-height: 1.5; }
  strong { color: var(--dark-gray); }
  em { color: var(--blue); font-style: italic; }

  table { font-size: 0.75em; border-collapse: collapse; width: 100%; margin-top: 0.5em; }
  th { background: var(--blue); color: white; font-weight: 500; padding: 8px 14px; text-align: left; }
  td { padding: 7px 14px; border-bottom: 1px solid #e0e0e0; color: var(--mid-gray); }
  tr:nth-child(even) td { background: var(--light-gray); }

  blockquote { border-left: 4px solid var(--blue); background: var(--light-gray); padding: 10px 20px; margin: 15px 0; font-size: 0.82em; color: var(--mid-gray); }
  blockquote strong { color: var(--dark-gray); }

  pre { font-size: 0.7em; background: var(--light-gray); padding: 16px 20px; border-radius: 6px; border-left: 4px solid var(--blue); }
  pre code { background: transparent; padding: 0; }
  code { font-size: 0.8em; background: var(--light-gray); padding: 2px 6px; border-radius: 3px; }

  footer { color: #aaa; font-size: 0.6em; }

  section.divider {
    background: var(--blue);
    color: white;
    justify-content: center;
    text-align: center;
  }
  section.divider h1 { background: transparent; color: white; font-size: 2.2em; margin: 0; padding: 0; }
  section.divider p { color: rgba(255,255,255,0.8); font-size: 1em; }
  section.divider footer { color: rgba(255,255,255,0.5); }
  section.divider::after { color: rgba(255,255,255,0.5); }

  section.highlight { background: var(--light-gray); }
</style>
```

### Slide structure rules

- **Section title slides**: Use `<!-- _class: lead -->` + `<!-- _paginate: skip -->` before `# Title` + `## Subtitle`
- **Content slides**: Use `# Slide Title` (renders as blue header bar) with body content below
- **Divider slides**: Use `<!-- _class: divider -->` for mid-section breaks
- **Slide separator**: Use `---` between slides
- **No Mermaid diagrams**: Marp PDF export doesn't render Mermaid. Use ASCII art box-drawing characters instead (e.g., `┌─┐`, `│`, `└─┘`, `───►`)
- **Tables**: Use standard markdown tables (they render with blue headers automatically)
- **Spacing**: Use `&nbsp;` for vertical spacing when needed

### 3. Create individual section files

Create a `slides/` subdirectory. For each section, create `slides/slides-XX.md` containing the full CSS style block + that section's slides only.

### 4. Generate PDFs

Generate the combined PDF and individual section PDFs:

```bash
bunx @marp-team/marp-cli slides.md --pdf --allow-local-files -o slides.pdf
```

For each section:
```bash
bunx @marp-team/marp-cli slides/slides-XX.md --pdf --allow-local-files -o slides/slides-XX.pdf
```

### 5. Verify

- Check that all PDFs were generated successfully
- Report the slide count and file sizes

## Important notes

- Always use `bunx` (not `npx`) for running marp-cli
- The `--allow-local-files` flag is required
- Each split file must include the full `<style>` block (it's not shared)
- Keep content concise — one idea per slide
- Use bold for key terms, tables for comparisons, code blocks for diagrams
- Blockquotes work well for callouts and key points
