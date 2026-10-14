// Pi extension: caps what one `read` or `bash` result can put into the model's context.
// Pi's own cap is 50 KB (~13k tokens); on a 64–128k local model a few parallel reads fill the window.
// Over the cap: `read` keeps the head and tells the model to page with offset/limit; `bash` keeps
// head + tail (errors and summaries sit at the end) and saves the full output to a temp file.
// Load with `pi -e <this file>`. Limits come from env so an eval can tune them:
// PI_RESULT_MAX_BYTES (default 12288), PI_RESULT_MAX_LINES (default 300).
// No imports from pi, so the file also type-checks in repos that don't install pi.
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";

interface TextPart {
  text: string;
  type: "text";
}
interface ResultEvent {
  content: Array<TextPart | { type: string }>;
  toolName: string;
}
interface PiApi {
  on(event: "tool_result", handler: (event: ResultEvent) => { content: TextPart[] } | undefined): void;
}

const MAX_BYTES = Number(process.env.PI_RESULT_MAX_BYTES ?? 12_288);
const MAX_LINES = Number(process.env.PI_RESULT_MAX_LINES ?? 300);
let spillDir: string | undefined;
let spills = 0;

function fits(text: string): boolean {
  return Buffer.byteLength(text) <= MAX_BYTES && text.split("\n").length <= MAX_LINES;
}

function headLines(lines: string[], maxLines: number, maxBytes: number): string[] {
  const kept: string[] = [];
  let bytes = 0;
  for (const line of lines) {
    bytes += Buffer.byteLength(line) + 1;
    if (kept.length >= maxLines || bytes > maxBytes) {
      break;
    }
    kept.push(line);
  }
  return kept;
}

function capRead(text: string): string {
  const lines = text.split("\n");
  const kept = headLines(lines, MAX_LINES, MAX_BYTES);
  return `${kept.join("\n")}\n\n[context-budget: showing ${kept.length} of ${lines.length} lines. Read the rest with offset/limit, or grep for what you need.]`;
}

function capBash(text: string): string {
  spillDir ??= mkdtempSync(path.join(tmpdir(), "pi-results-"));
  spills += 1;
  const file = path.join(spillDir, `output-${spills}.txt`);
  writeFileSync(file, text);
  const lines = text.split("\n");
  const head = headLines(lines, Math.floor(MAX_LINES / 3), Math.floor(MAX_BYTES / 3));
  const tail = headLines([...lines].reverse(), MAX_LINES - head.length, MAX_BYTES - Math.floor(MAX_BYTES / 3)).reverse();
  const omitted = lines.length - head.length - tail.length;
  return `${head.join("\n")}\n\n[context-budget: ${omitted} lines omitted; full output (${lines.length} lines) saved to ${file}. Use grep, or read it with offset/limit.]\n\n${tail.join("\n")}`;
}

export default function contextBudget(pi: PiApi) {
  pi.on("tool_result", (event) => {
    if (event.toolName !== "read" && event.toolName !== "bash") {
      return;
    }
    const texts = event.content.filter((part): part is TextPart => part.type === "text");
    const text = texts.map((part) => part.text).join("\n");
    if (texts.length !== event.content.length || fits(text)) {
      return;
    }
    return { content: [{ text: event.toolName === "read" ? capRead(text) : capBash(text), type: "text" }] };
  });
}
