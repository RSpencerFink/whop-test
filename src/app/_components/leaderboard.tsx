"use client";
import { TRPCError } from "@trpc/server";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "~/components/ui/table";
import type { Wallets, Profile } from "~/server/db/schema";
import { api } from "~/trpc/react";

type LeaderboardItem = Wallets & { profile: Profile | null; rank: number };

export const Leaderboard = () => {
  const { data, isLoading, error } = api.profile.getLeaderboard.useQuery({
    limit: 10,
  });

  if (isLoading) return <div>Loading...</div>;

  if (error && error instanceof TRPCError)
    return <div>Error: {error.message}</div>;

  if (!data) return <div>No data</div>;

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead className="w-[100px] text-white">User ID</TableHead>
          <TableHead className="text-white">User Name</TableHead>
          <TableHead className="text-white">Points Balance</TableHead>
          <TableHead className="text-right text-white">
            Leaderboard Rank
          </TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {(data ?? []).map((item) => (
          <LeaderboardItem key={item.profile?.id} item={item} />
        ))}
      </TableBody>
    </Table>
  );
};

const LeaderboardItem = ({ item }: { item: LeaderboardItem }) => {
  if (!item.profile) return null;
  return (
    <TableRow>
      <TableCell className="font-medium">{item.profile.id}</TableCell>
      <TableCell>{item.profile.name}</TableCell>
      <TableCell>{item.balance}</TableCell>
      <TableCell className="text-right">{item.rank}</TableCell>
    </TableRow>
  );
};
