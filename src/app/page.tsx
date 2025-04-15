import { HydrateClient } from "~/trpc/server";
import { Leaderboard } from "./_components/leaderboard";

export default async function Home() {
  return (
    <HydrateClient>
      <main className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-b from-[#02306d] to-[#15162c] text-white">
        <div className="container flex flex-col items-center justify-center gap-12 px-4 py-16">
          <h1 className="text-5xl font-extrabold tracking-tight sm:text-[5rem]">
            Whop Test - Leaderboard
          </h1>
          <Leaderboard />
        </div>
      </main>
    </HydrateClient>
  );
}
