import { z } from "zod";
import { createTRPCRouter, publicProcedure } from "~/server/api/trpc";
import { db } from "~/server/db";
import { points } from "~/server/db/schema";

export const profileRouter = createTRPCRouter({
  getLeaderboard: publicProcedure
    .input(z.object({ limit: z.number().min(1).max(100).default(10) }))
    .query(({ input }) => {
      const leaderboard = db.query.profiles.findMany({
        limit: input.limit,
        with: {
          points: {
            columns: {
              balance: true,
            },
          },
        },
        orderBy: (_, { desc }) => [desc(points.balance)],
      });

      return leaderboard;
    }),
});
