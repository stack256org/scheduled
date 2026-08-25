ALTER TYPE "public"."booking_status" ADD VALUE 'reschedule_requested' BEFORE 'cancelled';--> statement-breakpoint
ALTER TABLE "booking" ADD COLUMN "reschedule_requested_start" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "booking" ADD COLUMN "reschedule_requested_end" timestamp with time zone;