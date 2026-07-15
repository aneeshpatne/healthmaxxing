import { getAuth } from "@clerk/fastify";
import type { FastifyRequest, FastifyReply } from "fastify";
import { getOrCreateAccount } from "../services/account.service";

interface Account {
  id: string;
  mail_address: string | null;
  clerk_user_id: string | null;
  created_at: string;
  updated_at: string;
}

declare module "fastify" {
  interface FastifyRequest {
    auth: {
      clerkUserId: string;
      account: Account;
    };
  }
}

export async function authMiddleware(
  request: FastifyRequest,
  reply: FastifyReply,
) {
  const { isAuthenticated, userId } = getAuth(request);
  if (!isAuthenticated || !userId) {
    return reply.code(401).send({
      error: "Unauthorized",
    });
  }
  const account = await getOrCreateAccount(userId);

  request.auth = {
    clerkUserId: userId,
    account,
  };
}
