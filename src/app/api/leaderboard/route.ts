import { caller } from "~/trpc/server";

export async function GET(_request: Request) {
  const leaderboard = await caller.profile.getLeaderboard({});
  return new Response(JSON.stringify(leaderboard), { status: 200 });
}
