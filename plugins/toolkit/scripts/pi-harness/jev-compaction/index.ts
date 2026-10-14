// Pi extension: Jev decisions instead of Pi's LLM summary when Pi compacts (`session_before_compact`).
//
// Pi drops the messages before its cut point and replaces them with one summary text. This hook
// hands those messages to fast-jev-compaction instead: Jev decides per tool call whether the call,
// and whether its full result, still matter. Stale results are truncated, stale calls removed;
// all user and assistant text, and every kept call and result, stays verbatim. The kept transcript
// becomes the summary text, so file paths, exact errors and commands survive compaction.
//
// Data: the conversation state (tool inputs and texts; tool results reduced to their size) goes to
// TypeSafe's Jev API (api.typesafe.ai). That is the point of the hook; don't load it where the
// conversation may not leave the machine.
//
// Falls back to Pi's own summary (returns nothing) when TYPESAFE_API_KEY is unset, Jev fails or
// times out, the reduction is too small, or the verbatim result is still too large.
//   JEV_COMPACTION=off             disable without unloading the extension
//   JEV_MIN_REDUCTION (0.25)       minimum share of characters Jev must remove
//   JEV_MAX_SUMMARY_TOKENS (32000) ceiling for the verbatim summary (~4 chars per token)
//   JEV_KEEP_THRESHOLD (0.5)       keep probability below which a call or result goes
//   JEV_TIMEOUT_MS (60000)
//
// Load: `pi -e <this dir>` after `npm install` (or `bun install`) here once.
import { compactMessages, type Message, reductionRatio } from "fast-jev-compaction";

/** The parts of Pi's message and event types this hook reads (Pi's own types aren't a dependency). */
type Part = { type: string; text?: string; id?: string; name?: string; arguments?: Record<string, unknown> };
interface PiMessage {
  content?: string | Part[];
  isError?: boolean;
  role: string;
  toolCallId?: string;
}
interface CompactEvent {
  preparation: {
    firstKeptEntryId: string;
    isSplitTurn: boolean;
    messagesToSummarize: PiMessage[];
    previousSummary?: string;
    tokensBefore: number;
    turnPrefixMessages: PiMessage[];
  };
  signal?: AbortSignal;
}
interface CompactResult {
  compaction?: {
    details?: unknown;
    estimatedTokensAfter?: number;
    firstKeptEntryId: string;
    summary: string;
    tokensBefore: number;
  };
}
interface PiApi {
  on(event: "session_before_compact", handler: (event: CompactEvent) => Promise<CompactResult | undefined>): void;
}

export const MARKER = "[jev-compaction]";
const num = (name: string, fallback: number) => Number(process.env[name] ?? fallback);

function text(content: PiMessage["content"]): string {
  if (typeof content === "string") {
    return content;
  }
  return (content ?? [])
    .filter((p) => p.type === "text" && p.text)
    .map((p) => p.text)
    .join("\n");
}

/** Pi messages → Jev messages. A Pi tool result becomes a user message holding one tool_result. */
export function toJev(messages: PiMessage[]): Message[] {
  return messages.map((m): Message => {
    if (m.role === "assistant") {
      const calls = (Array.isArray(m.content) ? m.content : []).filter((p) => p.type === "toolCall");
      return {
        role: "assistant",
        text: text(m.content),
        toolUses: calls.map((c) => ({ input: c.arguments ?? {}, tool: c.name ?? "?", tool_use_id: c.id ?? "" })),
      };
    }
    if (m.role === "toolResult") {
      return {
        role: "user",
        text: "",
        toolResults: [{ isError: m.isError, text: text(m.content), tool_use_id: m.toolCallId ?? "" }],
        toolUses: [],
      };
    }
    // user, and Pi's own kinds (bash executions, summaries, custom messages): kept as text.
    const prefix = m.role === "user" ? "" : `[${m.role}] `;
    return { role: "user", text: `${prefix}${text(m.content)}`, toolUses: [] };
  });
}

/** Jev's kept transcript as summary text, in the line format Pi's own serializer uses. */
export function render(messages: Message[], previousSummary?: string): string {
  const names = new Map<string, string>();
  const lines = [
    `${MARKER} Earlier conversation, compacted by Jev: tool calls that no longer matter were removed and stale tool results truncated; everything below is verbatim.`,
  ];
  if (previousSummary) {
    lines.push("", "[Earlier compaction]:", previousSummary);
  }
  for (const m of messages) {
    if (m.text) {
      lines.push("", `[${m.role === "assistant" ? "Assistant" : "User"}]: ${m.text}`);
    }
    for (const u of m.toolUses) {
      names.set(u.tool_use_id, u.tool);
      lines.push("", `[Assistant tool call]: ${u.tool}(${JSON.stringify(u.input)})`);
    }
    for (const r of m.toolResults ?? []) {
      lines.push("", `[Tool result${r.isError ? ", error" : ""}: ${names.get(r.tool_use_id) ?? "tool"}]: ${r.text}`);
    }
  }
  return lines.join("\n");
}

export default function jevCompaction(pi: PiApi) {
  pi.on("session_before_compact", async (event) => {
    if (process.env.JEV_COMPACTION === "off" || !process.env.TYPESAFE_API_KEY) {
      return;
    }
    const { preparation, signal } = event;
    const source = [
      ...preparation.messagesToSummarize,
      ...(preparation.isSplitTurn ? preparation.turnPrefixMessages : []),
    ];
    if (source.length === 0) {
      return;
    }
    const timeout = AbortSignal.timeout(num("JEV_TIMEOUT_MS", 60_000));
    const abort = signal ? AbortSignal.any([signal, timeout]) : timeout;
    try {
      const result = await compactMessages(toJev(source), {
        fetch: (url, init) => fetch(url, { ...init, signal: abort }),
        keepThreshold: num("JEV_KEEP_THRESHOLD", 0.5),
        // Pi already keeps the recent messages outside this span; pin only the newest two here.
        preserveRecentMessages: 2,
      });
      const summary = render(result.messages, preparation.previousSummary);
      const tokens = Math.ceil(summary.length / 4);
      if (reductionRatio(result) < num("JEV_MIN_REDUCTION", 0.25) || tokens > num("JEV_MAX_SUMMARY_TOKENS", 32_000)) {
        return; // not worth it: Pi summarizes instead
      }
      return {
        compaction: {
          details: { jev: result.stats },
          estimatedTokensAfter: tokens,
          firstKeptEntryId: preparation.firstKeptEntryId,
          summary,
          tokensBefore: preparation.tokensBefore,
        },
      };
    } catch {
      return; // Jev failed or timed out: Pi summarizes instead
    }
  });
}
