ALTER TABLE "whop-test_points" RENAME TO "whop-test_wallets";--> statement-breakpoint
ALTER TABLE "whop-test_wallets" DROP CONSTRAINT "whop-test_points_profileId_whop-test_profiles_id_fk";
--> statement-breakpoint
ALTER TABLE "whop-test_wallets" ADD CONSTRAINT "whop-test_wallets_profileId_whop-test_profiles_id_fk" FOREIGN KEY ("profileId") REFERENCES "public"."whop-test_profiles"("id") ON DELETE cascade ON UPDATE no action;