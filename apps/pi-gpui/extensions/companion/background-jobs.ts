import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export const BACKGROUND_JOBS_STATUS_KEY = "\u001fpi-gpui-background-jobs\u001f";

interface BackgroundJob {
  name: string;
  command: string;
  state: "running";
}

interface PendingAsyncProcess {
  label: string;
  command: string;
}

function bounded(value: string, length: number): string {
  return value.length <= length ? value : `${value.slice(0, length - 1)}…`;
}

function processDetails(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object" ? value as Record<string, unknown> : undefined;
}

export default function backgroundJobs(pi: ExtensionAPI): void {
  const jobs = new Map<string, BackgroundJob>();
  const pendingProcesses = new Map<string, PendingAsyncProcess>();
  const settledBeforeStart = new Set<string>();

  const publish = (ctx: ExtensionContext): void => {
    ctx.ui.setStatus(BACKGROUND_JOBS_STATUS_KEY, JSON.stringify([...jobs.values()]));
  };

  pi.on("session_start", (_event, ctx) => {
    jobs.clear();
    pendingProcesses.clear();
    settledBeforeStart.clear();
    publish(ctx);
  });

  pi.on("tool_execution_start", (event) => {
    if (
      event.toolName !== "bash" ||
      event.args?.execution !== "async" ||
      typeof event.args.command !== "string" ||
      typeof event.args.label !== "string"
    ) return;
    pendingProcesses.set(event.toolCallId, {
      label: bounded(event.args.label, 80),
      command: bounded(event.args.command, 240),
    });
  });

  pi.on("tool_execution_end", (event, ctx) => {
    if (event.toolName !== "bash") return;
    const process = pendingProcesses.get(event.toolCallId);
    pendingProcesses.delete(event.toolCallId);
    const details = processDetails(event.result.details);
    const id = details?.state === "running" && typeof details.id === "string" ? details.id : undefined;
    if (event.isError || !process || !id) return;
    if (settledBeforeStart.delete(id)) return;
    jobs.set(id, { name: process.label, command: process.command, state: "running" });
    publish(ctx);
  });

  pi.on("message_end", (event, ctx) => {
    if (
      event.message.role !== "custom" ||
      !["process-session-status", "process-session-result"].includes(event.message.customType)
    ) return;
    const details = processDetails(event.message.details);
    if (
      typeof details?.id !== "string" ||
      !["completed", "exited", "failed"].includes(String(details.state))
    ) return;
    if (jobs.delete(details.id)) publish(ctx);
    else settledBeforeStart.add(details.id);
  });
}
