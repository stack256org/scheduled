ALTER TYPE "public"."booking_status" ADD VALUE 'pending' BEFORE 'confirmed';--> statement-breakpoint
ALTER TABLE "booking" ADD COLUMN "approval_token" text;--> statement-breakpoint
ALTER TABLE "booking" ADD COLUMN "rejection_reason" text;--> statement-breakpoint
CREATE INDEX "booking_approval_token_idx" ON "booking" USING btree ("approval_token");--> statement-breakpoint
ALTER TABLE "booking" ADD CONSTRAINT "booking_approval_token_unique" UNIQUE("approval_token");