import { createTRPCRouter } from "../trpc";

import { transactions, wallets } from "~/server/db/schema";

import { transactionsInsertSchema } from "~/server/db/schema";
import { publicProcedure } from "../trpc";
import { eq } from "drizzle-orm";
import { TRPCError } from "@trpc/server";

export const transactionRouter = createTRPCRouter({
  createTransaction: publicProcedure
    .input(transactionsInsertSchema.omit({ status: true }))
    .mutation(async ({ ctx, input }) => {
      if (input.senderId === input.recipientId) {
        await ctx.db.insert(transactions).values({
          ...input,
          status: "failed",
        });
        throw new TRPCError({
          code: "BAD_REQUEST",
          message: "Sender and recipient cannot be the same",
        });
      }
      if (input.amount <= 0) {
        await ctx.db.insert(transactions).values({
          ...input,
          status: "failed",
        });
        throw new TRPCError({
          code: "BAD_REQUEST",
          message: "Amount must be greater than 0",
        });
      }
      const senderWallet = await ctx.db.query.wallets.findFirst({
        where: eq(wallets.profileId, input.senderId),
      });
      if (!senderWallet) {
        await ctx.db.insert(transactions).values({
          ...input,
          status: "failed",
        });
        throw new TRPCError({
          code: "NOT_FOUND",
          message: "Sender wallet not found",
        });
      }
      if (input.senderId !== 1 && senderWallet.balance < input.amount) {
        await ctx.db.insert(transactions).values({
          ...input,
          status: "failed",
        });
        throw new TRPCError({
          code: "BAD_REQUEST",
          message: "Insufficient balance",
        });
      }
      const recipientWallet = await ctx.db.query.wallets.findFirst({
        where: eq(wallets.profileId, input.recipientId),
      });
      if (!recipientWallet) {
        await ctx.db.insert(transactions).values({
          ...input,
          status: "failed",
        });
        throw new TRPCError({
          code: "NOT_FOUND",
          message: "Recipient wallet not found",
        });
      }
      try {
        const transactionResult = await ctx.db.transaction(async (tx) => {
          // Insert the transaction
          const [transaction] = await tx
            .insert(transactions)
            .values({ ...input, status: "completed" })
            .returning();

          // Update sender wallet
          await tx
            .update(wallets)
            .set({ balance: senderWallet.balance - input.amount })
            .where(eq(wallets.profileId, input.senderId));

          // Update recipient wallet
          await tx
            .update(wallets)
            .set({ balance: recipientWallet.balance + input.amount })
            .where(eq(wallets.profileId, input.recipientId));

          return transaction;
        });

        return transactionResult;
      } catch (error) {
        console.error("Transaction error:", error);
        await ctx.db.insert(transactions).values({
          ...input,
          status: "failed",
        });
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "Failed to create transaction",
        });
      }
    }),
});
