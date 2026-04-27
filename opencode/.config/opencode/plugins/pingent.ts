import type { Plugin } from "@opencode-ai/plugin"

async function callPingent(payload: Record<string, unknown>) {
  const proc = Bun.spawn(["/home/jesper/bin/pingent"], {
    stdin: new Blob([JSON.stringify(payload)]),
    stdout: "ignore",
    stderr: "ignore",
  })

  await proc.exited
}

export const PingentPlugin: Plugin = async ({ directory }) => {
  const projectName = directory ? directory.split("/").filter(Boolean).pop() ?? "workspace" : "workspace"

  return {
    event: async ({ event }) => {
      if (event.type === "permission.asked") {
        await callPingent({ source: "opencode", event: "permission.asked", projectName })
      }
    },
    "tool.execute.before": async (input) => {
      if (input.tool === "question") {
        await callPingent({ source: "opencode", event: "question", projectName, tool: "question" })
      }
    },
  }
}

export default PingentPlugin
