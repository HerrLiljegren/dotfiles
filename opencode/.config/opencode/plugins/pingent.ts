import type { Plugin } from "@opencode-ai/plugin"

async function callPingent(payload: Record<string, unknown>) {
  const proc = Bun.spawn(["/home/jesper/bin/pingent"], {
    stdin: new Blob([JSON.stringify(payload)]),
    stdout: "pipe",
    stderr: "pipe",
  })

  const exitCode = await proc.exited
  const stdout = proc.stdout ? (await new Response(proc.stdout).text()).trim() : ""
  const stderr = proc.stderr ? (await new Response(proc.stderr).text()).trim() : ""

  return { exitCode, stdout, stderr }
}

export const PingentPlugin: Plugin = async ({ directory, client }) => {
  const projectName = directory ? directory.split("/").filter(Boolean).pop() ?? "workspace" : "workspace"

  return {
    event: async ({ event }) => {
      if (event.type === "permission.asked") {
        const result = await callPingent({ source: "opencode", event: "permission.asked", projectName })
        await client.app.log({
          body: {
            service: "pingent",
            level: "info",
            message: "permission.asked pingent result",
            extra: result,
          },
        })
      }

      if (event.type === "session.idle") {
        const result = await callPingent({ source: "opencode", event: "session.idle", projectName })
        await client.app.log({
          body: {
            service: "pingent",
            level: "info",
            message: "session.idle pingent result",
            extra: result,
          },
        })
      }

      if (event.type === "session.error") {
        const result = await callPingent({ source: "opencode", event: "session.error", projectName })
        await client.app.log({
          body: {
            service: "pingent",
            level: "info",
            message: "session.error pingent result",
            extra: result,
          },
        })
      }
    },
    "tool.execute.before": async (input) => {
      if (input.tool === "question") {
        const result = await callPingent({ source: "opencode", event: "question", projectName, tool: "question" })
        await client.app.log({
          body: {
            service: "pingent",
            level: "info",
            message: "question pingent result",
            extra: result,
          },
        })
      }
    },
  }
}

export default PingentPlugin
