import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import { profiles, wallets } from "./schema";
import { faker } from "@faker-js/faker";
import * as dotenv from "dotenv";
// to run: npx tsx ./src/server/db/seed.ts
// Load environment variables from .env file
dotenv.config();

async function main() {
  if (!process.env.DATABASE_URL) {
    throw new Error("DATABASE_URL is not set");
  }

  console.log("Using database URL:", process.env.DATABASE_URL);

  // Create postgres client
  const client = postgres(process.env.DATABASE_URL);

  // Create drizzle instance
  const db = drizzle(client);

  // Create profiles with points
  for (let i = 0; i < 100; i++) {
    // Insert profile
    const result = await db
      .insert(profiles)
      .values({
        name: faker.person.fullName(),
      })
      .returning();

    const profile = result[0];

    if (!profile) {
      console.error("Failed to insert profile");
      continue;
    }

    // Insert points for this profile
    await db.insert(wallets).values({
      profileId: profile.id,
      balance: faker.number.int({ min: 0, max: 10000 }),
    });
  }

  console.log("Seed completed successfully");
  await client.end();
}

void main().catch((e) => {
  console.error(e);
  process.exit(1);
});
