import { sql } from "../db/client";

export async function getOrCreateAccount(clerkUserId: string) {
  const id = Bun.randomUUIDv7();
  const [account] = await sql`
    INSERT into accounts (id, clerk_user_id)
    VALUES (${id},${clerkUserId})
    ON CONFLICT (clerk_user_id)
    DO UPDATE SET updated_at = NOW()
    RETURNING *`;
  return account;
}
