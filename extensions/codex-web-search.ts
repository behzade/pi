import { StringEnum, Type } from "@earendil-works/pi-ai";
import { Effect } from "effect";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  defineTool,
  type ExtensionAPI,
  type ExtensionContext,
  truncateHead,
} from "@earendil-works/pi-coding-agent";
import {
  buildCodexSearchRequest,
  extractCodexAccountId,
  parseCodexSearchResponse,
  redactCredential,
  type CodexSearchOptions,
} from "./lib/codex-web-search-core.ts";

const CODEX_SEARCH_URL = "https://chatgpt.com/backend-api/codex/alpha/search";
const SEARCH_TIMEOUT_MS = 60_000;

const parameters = Type.Object({
  query: Type.String({ description: "Web search query" }),
  recency: Type.Optional(StringEnum(["day", "week", "month", "year"] as const)),
  domains: Type.Optional(Type.Array(Type.String(), { description: "Allowed domains; prefix exclusions with -" })),
});

const webSearchTool = defineTool({
  name: "web_search",
  label: "Codex Web Search",
  description: "Search the current web through Codex and return its cited response.",
  parameters,
  execute(_toolCallId, params, signal, onUpdate, ctx) {
    const search = Effect.gen(function* () {
      const query = params.query.trim();
      if (!query) return yield* Effect.fail(new Error("Web search query must not be empty"));

      yield* Effect.sync(() => {
        onUpdate?.({ content: [{ type: "text", text: `Searching: ${query}` }], details: { phase: "searching" } });
      });
      const auth = yield* resolveCodexAuth(ctx);
      if (!auth) {
        return yield* Effect.fail(new Error("Codex Web Search requires an OpenAI Codex login. Use /login first."));
      }

      const headers: Record<string, string> = {
        ...stringHeaders(auth.headers),
        Authorization: `Bearer ${auth.apiKey}`,
        "Content-Type": "application/json",
        originator: "pi",
      };
      const accountId = extractCodexAccountId(auth.apiKey);
      if (accountId) headers["chatgpt-account-id"] = accountId;

      const options: CodexSearchOptions = {
        recency: params.recency,
        domains: params.domains,
      };
      return yield* Effect.gen(function* () {
        const { response, text } = yield* Effect.tryPromise({
          try: async (requestSignal) => {
            const response = await fetch(CODEX_SEARCH_URL, {
              method: "POST",
              headers,
              body: JSON.stringify(buildCodexSearchRequest(
                query,
                ctx.sessionManager.getSessionId(),
                auth.model,
                options,
              )),
              signal: requestSignal,
            });
            return { response, text: await response.text() };
          },
          catch: toError,
        });
        if (!response.ok) {
          return yield* Effect.fail(
            new Error(`Codex search error ${response.status}: ${text.slice(0, 500)}`),
          );
        }

        const parsed = yield* Effect.try({
          try: () => parseCodexSearchResponse(text),
          catch: toError,
        });
        const truncation = truncateHead(parsed.output, {
          maxBytes: DEFAULT_MAX_BYTES,
          maxLines: DEFAULT_MAX_LINES,
        });
        return {
          content: [{
            type: "text" as const,
            text: truncation.truncated
              ? `${truncation.content}\n\n[Codex search output truncated.]`
              : truncation.content,
          }],
          details: {
            model: auth.model,
            results: parsed.results,
            truncated: truncation.truncated,
          },
        };
      }).pipe(
        Effect.timeout(SEARCH_TIMEOUT_MS),
        Effect.catch((error) => Effect.fail(redactError(error, auth.apiKey))),
      );
    });

    return Effect.runPromise(search, { signal });
  },
});

export default function (pi: ExtensionAPI) {
  pi.registerTool(webSearchTool);
}

function resolveCodexAuth(ctx: ExtensionContext) {
  const model = ctx.model?.provider === "openai-codex"
    ? ctx.model
    : ctx.modelRegistry.getAll().find((candidate) => candidate.provider === "openai-codex");
  if (!model) return Effect.succeed(undefined);

  return Effect.tryPromise({
    try: () => ctx.modelRegistry.getApiKeyAndHeaders(model),
    catch: toError,
  }).pipe(
    Effect.map((resolved) => !resolved.ok || !resolved.apiKey ? undefined : {
      apiKey: resolved.apiKey,
      model: model.id,
      headers: resolved.headers ?? {},
    }),
    Effect.catch(() => Effect.succeed(undefined)),
  );
}

function redactError(error: unknown, credential: string): Error {
  const original = error instanceof Error ? error.message : String(error);
  const message = redactCredential(original, credential);
  return message === original && error instanceof Error ? error : new Error(message);
}

function toError(error: unknown): Error {
  return error instanceof Error ? error : new Error(String(error));
}

function stringHeaders(headers: Record<string, string | null>): Record<string, string> {
  return Object.fromEntries(Object.entries(headers).filter((entry): entry is [string, string] => entry[1] !== null));
}
