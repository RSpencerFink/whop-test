import { TRPCError } from "@trpc/server";
import type { NextRequest } from "next/server";
import { caller } from "~/trpc/server";

interface PayRequest extends NextRequest {
  json: () => Promise<{
    amount: number;
    recipient_id: number;
  }>;
}

export async function POST(request: PayRequest) {
  const { amount, recipient_id } = await request.json();
  const headers = new Headers(request.headers);
  const senderId = headers.get("x-user-id");

  if (!senderId || isNaN(parseInt(senderId))) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
    });
  }
  try {
    const transaction = await caller.transaction.createTransaction({
      amount,
      recipientId: recipient_id,
      senderId: parseInt(senderId),
    });
    return new Response(JSON.stringify(transaction), { status: 200 });
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
