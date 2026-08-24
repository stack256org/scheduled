CREATE TYPE "public"."meeting_limit_period" AS ENUM('day', 'week', 'month');--> statement-breakpoint
CREATE TYPE "public"."meeting_type" AS ENUM('one_on_one', 'group', 'round_robin', 'collective');--> statement-breakpoint
CREATE TABLE "meeting_limit" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"period" "meeting_limit_period" NOT NULL,
	"count" integer NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "booking_blocklist" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"pattern" text NOT NULL,
	"type" text NOT NULL,
	"note" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "booking" DROP CONSTRAINT "booking_event_type_id_event_type_id_fk";
--> statement-breakpoint
ALTER TABLE "booking" DROP CONSTRAINT "booking_host_user_id_user_id_fk";
--> statement-breakpoint
ALTER TABLE "event_type" ADD COLUMN "meeting_type" "meeting_type" DEFAULT 'one_on_one' NOT NULL;--> statement-breakpoint
ALTER TABLE "event_type" ADD COLUMN "requires_email_verification" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "meeting_limit" ADD CONSTRAINT "meeting_limit_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking_blocklist" ADD CONSTRAINT "booking_blocklist_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking" ADD CONSTRAINT "booking_event_type_id_event_type_id_fk" FOREIGN KEY ("event_type_id") REFERENCES "public"."event_type"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking" ADD CONSTRAINT "booking_host_user_id_user_id_fk" FOREIGN KEY ("host_user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;