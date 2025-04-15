// Example model schema from the Drizzle docs
// https://orm.drizzle.team/docs/sql-schema-declaration

import { relations, sql } from "drizzle-orm";
import {
  uniqueIndex,
  integer,
  pgTableCreator,
  timestamp,
  varchar,
} from "drizzle-orm/pg-core";
import { createInsertSchema, createSelectSchema } from "drizzle-zod";

/**
 * This is an example of how to use the multi-project schema feature of Drizzle ORM. Use the same
 * database instance for multiple projects.
 *
 * @see https://orm.drizzle.team/docs/goodies#multi-project-schema
 */
export const createTable = pgTableCreator((name) => `whop-test_${name}`);

const timestamps = {
  createdAt: timestamp({ withTimezone: true })
    .default(sql`CURRENT_TIMESTAMP`)
    .notNull(),
  updatedAt: timestamp({ withTimezone: true }).$onUpdate(() => new Date()),
};

// Profiles table
export const profiles = createTable("profiles", {
  id: integer().primaryKey().generatedByDefaultAsIdentity(),
  name: varchar({ length: 256 }),
  ...timestamps,
});

export type Profile = typeof profiles.$inferSelect;
export type NewProfile = typeof profiles.$inferInsert;

export const profileSelectSchema = createSelectSchema(profiles);
export const profileInsertSchema = createInsertSchema(profiles);

export const profileRelations = relations(profiles, ({ one }) => ({
  wallets: one(wallets, {
    fields: [profiles.id],
    references: [wallets.profileId],
  }),
}));

// Points table
export const wallets = createTable(
  "wallets",
  {
    id: integer().primaryKey().generatedByDefaultAsIdentity(),
    profileId: integer()
      .references(() => profiles.id, {
        onDelete: "cascade",
      })
      .notNull(),
    balance: integer().default(0),
    ...timestamps,
  },
  (t) => [uniqueIndex("profile_index").on(t.profileId)],
);

export type Wallets = typeof wallets.$inferSelect;
export type NewWallets = typeof wallets.$inferInsert;

export const walletsSelectSchema = createSelectSchema(wallets);
export const walletsInsertSchema = createInsertSchema(wallets);

export const walletsRelations = relations(wallets, ({ one }) => ({
  profile: one(profiles),
}));
