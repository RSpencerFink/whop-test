import { z } from "zod";
import { createTRPCRouter, publicProcedure } from "~/server/api/trpc";
import { db } from "~/server/db";
import { points } from "~/server/db/schema";
import { sql } from "drizzle-orm";

export const profileRouter = createTRPCRouter({
  getLeaderboard: publicProcedure
    .input(z.object({ limit: z.number().min(1).max(100).default(100) }))
    .query(async ({ input }) => {
      // fetch highest balance points and associated profile data
      const leaderboard = await db.query.points.findMany({
        limit: input.limit,
        with: {
          profile: true,
        },
        orderBy: (points, { desc }) => [desc(points.balance)],
        extras: {
          rank: sql<number>`dense_rank() over (order by ${points.balance} desc)`.as(
            "rank",
          ),
        },
      });
      return leaderboard;
    }),
});
