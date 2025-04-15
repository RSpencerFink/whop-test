import { leaderboardRouter } from "~/server/api/routers/leaderboard";
import { createCallerFactory, createTRPCRouter } from "~/server/api/trpc";
import { transactionRouter } from "~/server/api/routers/transaction";
import { walletRouter } from "~/server/api/routers/wallet";
/**
 * This is the primary router for your server.
 *
 * All routers added in /api/routers should be manually added here.
 */
export const appRouter = createTRPCRouter({
  leaderboard: leaderboardRouter,
  transaction: transactionRouter,
  wallet: walletRouter,
});

// export type definition of API
export type AppRouter = typeof appRouter;

/**
 * Create a server-side caller for the tRPC API.
 * @example
 * const trpc = createCaller(createContext);
 * const res = await trpc.post.all();
 *       ^? Post[]
 */
export const createCaller = createCallerFactory(appRouter);
