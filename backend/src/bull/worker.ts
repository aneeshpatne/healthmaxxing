import { Job, Worker } from "bullmq";
import { runAgentOrchestratorNew } from "../ai/agentOrchestratorNew";
import {
  getProfileAiReportById,
  updateProfileInsightReportGenerationStatus,
} from "../db/commands";
import { connection } from "./queue";

export function startWorker() {
  const worker = new Worker(
    "jobs",
    async (job: Job) => {
      if (job.name === "generate_report") {
        const { profileId, reportId } = job.data as {
          profileId: string;
          reportId: string;
        };

        await updateProfileInsightReportGenerationStatus({
          reportId,
          profileId,
          status: "running",
        });

        try {
          const agentResult = await runAgentOrchestratorNew(profileId, reportId);
          if (agentResult.toolCallCount !== 1) {
            throw new Error(
              `Report agent must call profile_ai_report exactly once; received ${agentResult.toolCallCount}`,
            );
          }
          const persisted = await getProfileAiReportById({ profileId, reportId });
          if (persisted?.data === null || persisted === null) {
            throw new Error("Report agent completed without persisting structured output");
          }
          await updateProfileInsightReportGenerationStatus({
            reportId,
            profileId,
            status: "completed",
          });
        } catch (error) {
          const finalAttempt =
            job.attemptsMade + 1 >= (job.opts.attempts ?? 1);
          await updateProfileInsightReportGenerationStatus({
            reportId,
            profileId,
            status: finalAttempt ? "failed" : "queued",
            error: error instanceof Error ? error.message : String(error),
          });
          throw error;
        }

        return;
      }

      throw new Error(`Unknown job name: ${job.name}`);
    },
    { connection },
  );

  worker.on("ready", () => {
    console.log("[worker] ready");
  });

  worker.on("failed", (job, error) => {
    console.error("[worker] job failed", {
      id: job?.id,
      name: job?.name,
      error,
    });
  });

  worker.on("error", (error) => {
    console.error("[worker] error", error);
  });

  return worker;
}

const isMainModule =
  typeof Bun !== "undefined" &&
  Bun.main === new URL(import.meta.url).pathname;

if (isMainModule) {
  startWorker();
}
