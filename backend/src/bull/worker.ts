import { Queue, Worker } from "bullmq";

const redisUrl = new URL(process.env.REDIS_URL ?? "redis://localhost:6379");
const connection = {
  host: redisUrl.hostname,
  port: Number(redisUrl.port || "6379"),
  username: redisUrl.username || undefined,
  password: redisUrl.password || undefined,
  db: redisUrl.pathname.length > 1 ? Number(redisUrl.pathname.slice(1)) : undefined,
};

const queue = new Queue("jobs", { connection });

export async function addPdfJob({ pdfbase64 }: { pdfbase64: string }) {
  await queue.add("process_pdf", { pdfbase64 });
}

const worker = new Worker(
  "jobs",
  async (job) => {
    const data = job.data.pdfbase64;
    console.log(data);
  },
  { connection },
);

worker.on("completed", (job) => {
  console.log(`Job ${job?.id} completed`);
});

worker.on("failed", (job, err) => {
  console.error(`Job ${job?.id} failed`, err);
});
