import { z } from "zod";
import { publicProcedure } from "../trpc";

import { createTRPCRouter } from "../trpc";
import { wallets, walletsInsertSchema } from "~/server/db/schema";
import { eq } from "drizzle-orm";
import { TRPCError } from "@trpc/server";

export const walletRouter = createTRPCRouter({
  getWalletForUser: publicProcedure
    .input(z.object({ userId: z.number() }))
    .query(async ({ ctx, input }) => {
      const wallet = await ctx.db.query.wallets.findFirst({
        where: eq(wallets.profileId, input.userId),
      });
      if (!wallet) {
        throw new TRPCError({
          code: "NOT_FOUND",
          message: "Wallet not found",
        });
      }
      return wallet;
    }),
  getBalanceForUser: publicProcedure
    .input(z.object({ userId: z.number() }))
    .query(async ({ ctx, input }) => {
      const wallet = await ctx.db.query.wallets.findFirst({
        where: eq(wallets.profileId, input.userId),
        columns: {
          balance: true,
        },
      });
      if (!wallet) {
        throw new TRPCError({
          code: "NOT_FOUND",
          message: "Wallet not found",
        });
      }
      return wallet.balance;
    }),
  updateWallet: publicProcedure
    .input(walletsInsertSchema)
    .mutation(async ({ ctx, input }) => {
      const wallet = await ctx.db
        .update(wallets)
        .set(input)
        .where(eq(wallets.profileId, input.profileId));
      return wallet;
    }),
});
