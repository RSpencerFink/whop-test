import { caller } from "~/trpc/server";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const limit = searchParams.get("limit") ?? "10";
  const leaderboard = await caller.profile.getLeaderboard({
    limit: parseInt(limit),
  });
  return new Response(JSON.stringify(leaderboard), { status: 200 });
}
