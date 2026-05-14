import { redis, RedisClient } from "bun";
const pub = new RedisClient("redis://localhost:6379");
export async function publishJobStatus(
  jobId: string,
  status: string,
): Promise<void> {
  const statusRaw = await redis.get(`status:${jobId}`);

  if (statusRaw === null) {
    return;
  }

  const currentStatus = JSON.parse(statusRaw) as {
    status?: string;
    version?: number;
  };
  const nextStatus = {
    ...currentStatus,
    status,
    version: (currentStatus.version ?? 0) + 1,
    updatedAt: Date.now(),
  };
  const message = JSON.stringify(nextStatus);

  await redis.set(`status:${jobId}`, message);
  await pub.publish(`status:${jobId}`, message);
}
