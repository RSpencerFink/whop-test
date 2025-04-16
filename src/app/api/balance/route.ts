import { TRPCError } from "@trpc/server";
import type { NextRequest } from "next/server";
import { caller } from "~/trpc/server";

export async function GET(request: NextRequest) {
  const headers = new Headers(request.headers);
  const senderId = headers.get("x-user-id");

  if (!senderId || isNaN(parseInt(senderId))) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
    });
  }
  try {
    const balance = await caller.wallet.getBalanceForUser({
      userId: parseInt(senderId),
    });
    return new Response(JSON.stringify({ amount: balance }), { status: 200 });
  } catch (error) {
    if (error instanceof TRPCError) {
      return new Response(
        JSON.stringify({ ...error, message: error.message }),
        {
          status: 500,
        },
      );
    }
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
    });
  }
}
