import { Job, Worker } from "bullmq";
import { runAgentOrchestratorNew } from "../ai/agentOrchestratorNew";
import { updateProfileInsightReportGenerationStatus } from "../db/commands";
import { connection } from "./queue";

const worker = new Worker("jobs", async (job: Job) => {
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
      await runAgentOrchestratorNew(profileId, reportId);
      await updateProfileInsightReportGenerationStatus({
        reportId,
        profileId,
        status: "completed",
      });
    } catch (error) {
      await updateProfileInsightReportGenerationStatus({
        reportId,
        profileId,
        status: "failed",
        error: error instanceof Error ? error.message : String(error),
      });
      throw error;
    }

    return;
  }

  throw new Error(`Unknown job name: ${job.name}`);
}, { connection });

worker.on("failed", (job, error) => {
  console.error("[worker] job failed", {
    id: job?.id,
    name: job?.name,
    error,
  });
});
