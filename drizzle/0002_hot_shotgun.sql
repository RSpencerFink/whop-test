CREATE TABLE "whop-test_points" (
	"id" integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY (sequence name "whop-test_points_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"profileId" integer,
	"balance" integer DEFAULT 0,
	"createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updatedAt" timestamp with time zone
);
--> statement-breakpoint
ALTER TABLE "whop-test_points" ADD CONSTRAINT "whop-test_points_profileId_whop-test_profiles_id_fk" FOREIGN KEY ("profileId") REFERENCES "public"."whop-test_profiles"("id") ON DELETE no action ON UPDATE no action;