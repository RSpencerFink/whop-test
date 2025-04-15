ALTER TABLE "whop-test_points" DROP CONSTRAINT "whop-test_points_profileId_whop-test_profiles_id_fk";
--> statement-breakpoint
ALTER TABLE "whop-test_points" ALTER COLUMN "profileId" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "whop-test_points" ADD CONSTRAINT "whop-test_points_profileId_whop-test_profiles_id_fk" FOREIGN KEY ("profileId") REFERENCES "public"."whop-test_profiles"("id") ON DELETE cascade ON UPDATE no action;