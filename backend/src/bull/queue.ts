import { Queue } from "bullmq";

const redisUrl = new URL(process.env.REDIS_URL ?? "redis://localhost:6379");

export const connection = {
  host: redisUrl.hostname,
  port: Number(redisUrl.port || "6379"),
  username: redisUrl.username || undefined,
  password: redisUrl.password || undefined,
  db:
    redisUrl.pathname.length > 1
      ? Number(redisUrl.pathname.slice(1))
      : undefined,
};

type GenerateReportJob = {
  reportId: string;
  profileId: string;
};

const queue = new Queue<GenerateReportJob>("jobs", { connection });

export async function addQueueItem(reportId: string, profileId: string) {
  return await queue.add("generate_report", { reportId, profileId });
}
