"use client";
import { TRPCError } from "@trpc/server";
import type { Points, Profile } from "~/server/db/schema";
import { api } from "~/trpc/react";

export const Leaderboard = () => {
  const { data, isLoading, error } = api.profile.getLeaderboard.useQuery({
    limit: 10,
  });

  if (isLoading) return <div>Loading...</div>;

  if (error && error instanceof TRPCError)
    return <div>Error: {error.message}</div>;

  if (!data) return <div>No data</div>;

  return (
    <div>
      {data?.map((item) => {
        if (!item.profile) return null;
        return <LeaderboardItem key={item.profile.id} item={item} />;
      })}
    </div>
  );
};

const LeaderboardItem = ({ item }: { item: Points & { profile: Profile } }) => {
  return (
    <div>
      {item.profile.id} - {item.balance} - {item.rank}
    </div>
  );
};
