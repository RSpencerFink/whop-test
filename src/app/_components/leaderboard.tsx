"use client";
import { TRPCError } from "@trpc/server";
import type { Profile } from "~/server/db/schema";
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
      {data?.map((profile: Profile) => (
        <LeaderboardItem key={profile.id} profile={profile} />
      ))}
    </div>
  );
};

const LeaderboardItem = ({ profile }: { profile: Profile }) => {
  return <div>{profile.id}</div>;
};
