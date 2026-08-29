import assert from "node:assert/strict";
import test from "node:test";

import backgroundJobs, {
  BACKGROUND_JOBS_STATUS_KEY,
} from "./companion/background-jobs.ts";

function harness() {
  const handlers = new Map();
  const snapshots = [];
  backgroundJobs({
    on(event, callback) {
      handlers.set(event, callback);
    },
  });
  const ctx = {
    ui: {
      setStatus(key, text) {
        assert.equal(key, BACKGROUND_JOBS_STATUS_KEY);
        snapshots.push(JSON.parse(text));
      },
    },
  };
  return { handlers, snapshots, ctx };
}

async function startAsyncProcess(handlers, ctx, toolCallId = "bash-call") {
  await handlers.get("tool_execution_start")({
    toolCallId,
    toolName: "bash",
    args: { command: "cargo test", execution: "async", label: "Long tests" },
  }, ctx);
}

async function finishAsyncStart(handlers, ctx, id = "pi-process", toolCallId = "bash-call") {
  await handlers.get("tool_execution_end")({
    toolCallId,
    toolName: "bash",
    result: { details: { id, state: "running" } },
    isError: false,
  }, ctx);
}

async function settleAsyncProcess(handlers, ctx, id = "pi-process", customType = "process-session-status") {
  await handlers.get("message_end")({
    message: {
      role: "custom",
      customType,
      details: { id, state: "exited", exitCode: 7 },
    },
  }, ctx);
}

test("publishes active async processes and removes them on settlement", async () => {
  const { handlers, snapshots, ctx } = harness();
  await handlers.get("session_start")({}, ctx);
  await startAsyncProcess(handlers, ctx);
  await finishAsyncStart(handlers, ctx);

  assert.deepEqual(snapshots.at(-1), [{
    name: "Long tests",
    command: "cargo test",
    state: "running",
  }]);

  await settleAsyncProcess(handlers, ctx);
  assert.deepEqual(snapshots.at(-1), []);
});

test("does not resurrect an async process settled before its start result", async () => {
  const { handlers, snapshots, ctx } = harness();
  await handlers.get("session_start")({}, ctx);
  await startAsyncProcess(handlers, ctx);
  await settleAsyncProcess(handlers, ctx, "pi-process", "process-session-result");
  await finishAsyncStart(handlers, ctx);

  assert.deepEqual(snapshots, [[]]);
});

test("ignores synchronous and failed async calls", async () => {
  const { handlers, snapshots, ctx } = harness();
  await handlers.get("session_start")({}, ctx);

  await handlers.get("tool_execution_start")({
    toolCallId: "sync",
    toolName: "bash",
    args: { command: "cargo test" },
  }, ctx);
  await handlers.get("tool_execution_end")({
    toolCallId: "sync",
    toolName: "bash",
    result: { details: undefined },
    isError: false,
  }, ctx);

  await startAsyncProcess(handlers, ctx, "failed");
  await handlers.get("tool_execution_end")({
    toolCallId: "failed",
    toolName: "bash",
    result: { details: { id: "pi-failed", state: "running" } },
    isError: true,
  }, ctx);

  assert.deepEqual(snapshots, [[]]);
});
