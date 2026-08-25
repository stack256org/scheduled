DROP INDEX "event_type_user_slug_idx";--> statement-breakpoint
ALTER TABLE "event_type" ADD COLUMN "booking_range_start" date;--> statement-breakpoint
ALTER TABLE "event_type" ADD COLUMN "booking_range_end" date;--> statement-breakpoint
CREATE UNIQUE INDEX "calendar_event_cache_cal_event_unq" ON "calendar_event_cache" USING btree ("connected_calendar_id","external_event_id");--> statement-breakpoint
CREATE UNIQUE INDEX "video_connection_user_provider_unq" ON "video_connection" USING btree ("user_id","provider");--> statement-breakpoint
CREATE UNIQUE INDEX "event_type_user_slug_idx" ON "event_type" USING btree ("user_id","slug");