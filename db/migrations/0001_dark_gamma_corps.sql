CREATE TYPE "public"."audit_action" AS ENUM('user.signup', 'user.signin', 'user.signout', 'user.password_reset', 'user.ban', 'user.unban', 'user.impersonate_start', 'user.impersonate_stop', 'user.revoke_sessions', 'user.profile_updated', 'user.timezone_changed', 'user.username_changed', 'user.photo_updated', 'user.password_changed', 'user.email_change_requested', 'user.account_deleted', 'user.branding_updated', 'booking.created', 'booking.cancelled_by_invitee', 'booking.cancelled_by_host', 'booking.rescheduled', 'event_type.created', 'event_type.updated', 'event_type.deleted', 'event_type.activated', 'event_type.deactivated', 'availability.schedule_updated', 'availability.override_added', 'availability.override_removed', 'availability.schedule_assigned', 'calendar.connected', 'calendar.disconnected');--> statement-breakpoint
CREATE TYPE "public"."audit_source" AS ENUM('web', 'api', 'worker', 'system');--> statement-breakpoint
CREATE TYPE "public"."booking_status" AS ENUM('confirmed', 'cancelled', 'rescheduled', 'completed', 'no_show');--> statement-breakpoint
CREATE TYPE "public"."booking_window_type" AS ENUM('rolling', 'fixed');--> statement-breakpoint
CREATE TYPE "public"."calendar_provider" AS ENUM('google', 'outlook', 'apple', 'caldav');--> statement-breakpoint
CREATE TYPE "public"."calendar_status" AS ENUM('connected', 'disconnected');--> statement-breakpoint
CREATE TYPE "public"."date_format" AS ENUM('MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD');--> statement-breakpoint
CREATE TYPE "public"."day_of_week" AS ENUM('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');--> statement-breakpoint
CREATE TYPE "public"."job_status" AS ENUM('pending', 'running', 'completed', 'failed', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."location_type" AS ENUM('zoom', 'google_meet', 'phone_host_calls', 'phone_invitee_calls', 'in_person', 'custom', 'invitees_choice');--> statement-breakpoint
CREATE TYPE "public"."question_type" AS ENUM('short_text', 'long_text', 'phone', 'single_select', 'dropdown', 'multiple_select', 'number', 'date', 'url');--> statement-breakpoint
CREATE TYPE "public"."theme" AS ENUM('light', 'dark', 'system');--> statement-breakpoint
CREATE TYPE "public"."time_format" AS ENUM('12h', '24h');--> statement-breakpoint
CREATE TYPE "public"."video_provider" AS ENUM('zoom', 'teams');--> statement-breakpoint
CREATE TABLE "user_branding" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"brand_primary_color" text DEFAULT '#0d9488',
	"brand_text_color" text DEFAULT '#ffffff',
	"logo_url" text,
	"welcome_message" text,
	"confirmation_message" text,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "user_branding_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "user_profile" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"display_name" text,
	"job_title" text,
	"company" text,
	"bio" text,
	"website_url" text,
	"theme" "theme" DEFAULT 'system',
	"date_format" date_format DEFAULT 'MM/DD/YYYY',
	"time_format" time_format DEFAULT '12h',
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "user_profile_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "username_redirect" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"old_username" text NOT NULL,
	"new_username" text NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "contact" (
	"id" text PRIMARY KEY NOT NULL,
	"host_user_id" text NOT NULL,
	"email" text NOT NULL,
	"name" text NOT NULL,
	"notes" text,
	"is_archived" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "cancellation_policy" (
	"id" text PRIMARY KEY NOT NULL,
	"event_type_id" text NOT NULL,
	"allow_cancellation" boolean DEFAULT true NOT NULL,
	"cutoff_hours" integer DEFAULT 0,
	"allow_rescheduling" boolean DEFAULT true NOT NULL,
	"reschedule_cutoff_hours" integer DEFAULT 0,
	"max_reschedules" integer,
	"require_cancellation_reason" boolean DEFAULT false NOT NULL,
	"cancellation_reason_options" jsonb,
	"show_policy_text" boolean DEFAULT true NOT NULL,
	"policy_text" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "cancellation_policy_event_type_id_unique" UNIQUE("event_type_id")
);
--> statement-breakpoint
CREATE TABLE "event_type" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"availability_schedule_id" text,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"description" text,
	"location_type" "location_type" DEFAULT 'zoom' NOT NULL,
	"location_value" text,
	"host_phone_number" text,
	"color" text DEFAULT '#0d9488',
	"is_active" boolean DEFAULT true NOT NULL,
	"is_hidden" boolean DEFAULT false NOT NULL,
	"position" integer DEFAULT 0,
	"minimum_notice" integer DEFAULT 60,
	"booking_window" integer DEFAULT 60,
	"booking_window_type" "booking_window_type" DEFAULT 'rolling',
	"buffer_before" integer DEFAULT 0,
	"buffer_after" integer DEFAULT 0,
	"max_bookings_per_day" integer,
	"start_time_increment" integer DEFAULT 30,
	"requires_approval" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "event_type_duration" (
	"id" text PRIMARY KEY NOT NULL,
	"event_type_id" text NOT NULL,
	"duration" integer NOT NULL,
	"is_default" boolean DEFAULT false NOT NULL
);
--> statement-breakpoint
CREATE TABLE "event_type_question" (
	"id" text PRIMARY KEY NOT NULL,
	"event_type_id" text NOT NULL,
	"label" text NOT NULL,
	"type" "question_type" NOT NULL,
	"is_required" boolean DEFAULT false NOT NULL,
	"options" jsonb,
	"placeholder" text,
	"position" integer DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL
);
--> statement-breakpoint
CREATE TABLE "availability_override" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"date" text NOT NULL,
	"is_blocked" boolean DEFAULT true NOT NULL,
	"start_time" text,
	"end_time" text,
	"reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "availability_schedule" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"name" text DEFAULT 'Working Hours' NOT NULL,
	"is_default" boolean DEFAULT true NOT NULL,
	"timezone" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "availability_window" (
	"id" text PRIMARY KEY NOT NULL,
	"schedule_id" text NOT NULL,
	"day_of_week" "day_of_week" NOT NULL,
	"start_time" text NOT NULL,
	"end_time" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "calendar_event_cache" (
	"id" text PRIMARY KEY NOT NULL,
	"connected_calendar_id" text NOT NULL,
	"external_event_id" text NOT NULL,
	"start_time" timestamp with time zone NOT NULL,
	"end_time" timestamp with time zone NOT NULL,
	"is_busy" boolean DEFAULT true NOT NULL,
	"synced_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "connected_calendar" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"provider" "calendar_provider" NOT NULL,
	"account_email" text NOT NULL,
	"access_token" text,
	"refresh_token" text,
	"token_expires_at" timestamp with time zone,
	"status" "calendar_status" DEFAULT 'connected' NOT NULL,
	"disconnected_at" timestamp with time zone,
	"calendar_id" text,
	"calendar_name" text,
	"is_primary" boolean DEFAULT false NOT NULL,
	"is_conflict_check" boolean DEFAULT true NOT NULL,
	"is_write_target" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "video_connection" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"provider" "video_provider" NOT NULL,
	"account_email" text,
	"access_token" text NOT NULL,
	"refresh_token" text,
	"token_expires_at" timestamp with time zone,
	"provider_user_id" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "booking" (
	"id" text PRIMARY KEY NOT NULL,
	"event_type_id" text NOT NULL,
	"host_user_id" text NOT NULL,
	"invitee_name" text NOT NULL,
	"invitee_email" text NOT NULL,
	"invitee_phone" text,
	"invitee_timezone" text NOT NULL,
	"start_time" timestamp with time zone NOT NULL,
	"end_time" timestamp with time zone NOT NULL,
	"duration" integer NOT NULL,
	"location_value" text,
	"video_link_host" text,
	"video_link_invitee" text,
	"status" "booking_status" DEFAULT 'confirmed' NOT NULL,
	"cancel_token" text NOT NULL,
	"reschedule_token" text NOT NULL,
	"cancel_token_expires_at" timestamp with time zone,
	"reschedule_token_expires_at" timestamp with time zone,
	"cancellation_reason" text,
	"cancelled_by" text,
	"cancelled_at" timestamp with time zone,
	"rescheduled_from_id" text,
	"reschedule_count" integer DEFAULT 0 NOT NULL,
	"host_notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "booking_cancel_token_unique" UNIQUE("cancel_token"),
	CONSTRAINT "booking_reschedule_token_unique" UNIQUE("reschedule_token")
);
--> statement-breakpoint
CREATE TABLE "booking_answer" (
	"id" text PRIMARY KEY NOT NULL,
	"booking_id" text NOT NULL,
	"question_id" text,
	"question_label" text NOT NULL,
	"answer" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "booking_guest" (
	"id" text PRIMARY KEY NOT NULL,
	"booking_id" text NOT NULL,
	"guest_email" text NOT NULL,
	"guest_name" text
);
--> statement-breakpoint
CREATE TABLE "notification_preference" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"booking_confirmation_email" boolean DEFAULT true NOT NULL,
	"booking_notification_email" boolean DEFAULT true NOT NULL,
	"reminder_email_24h" boolean DEFAULT true NOT NULL,
	"reminder_email_1h" boolean DEFAULT true NOT NULL,
	"cancellation_email" boolean DEFAULT true NOT NULL,
	"reschedule_email" boolean DEFAULT true NOT NULL,
	"from_name" text,
	"reply_to_email" text,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "notification_preference_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "workflow_job" (
	"id" text PRIMARY KEY NOT NULL,
	"booking_id" text NOT NULL,
	"job_type" text NOT NULL,
	"singleton_key" text NOT NULL,
	"scheduled_for" timestamp with time zone,
	"status" "job_status" DEFAULT 'pending' NOT NULL,
	"completed_at" timestamp with time zone,
	"failure_reason" text,
	"retry_count" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "idempotency_key" (
	"id" text PRIMARY KEY NOT NULL,
	"key" text NOT NULL,
	"result" text,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "idempotency_key_key_unique" UNIQUE("key")
);
--> statement-breakpoint
ALTER TABLE "user" ADD COLUMN "username" text;--> statement-breakpoint
ALTER TABLE "user" ADD COLUMN "timezone" text DEFAULT 'UTC';--> statement-breakpoint
ALTER TABLE "user" ADD COLUMN "onboarding_step" integer DEFAULT 0;--> statement-breakpoint
ALTER TABLE "user" ADD COLUMN "onboarding_done" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "user_branding" ADD CONSTRAINT "user_branding_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_profile" ADD CONSTRAINT "user_profile_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "username_redirect" ADD CONSTRAINT "username_redirect_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "contact" ADD CONSTRAINT "contact_host_user_id_user_id_fk" FOREIGN KEY ("host_user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "cancellation_policy" ADD CONSTRAINT "cancellation_policy_event_type_id_event_type_id_fk" FOREIGN KEY ("event_type_id") REFERENCES "public"."event_type"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "event_type" ADD CONSTRAINT "event_type_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "event_type_duration" ADD CONSTRAINT "event_type_duration_event_type_id_event_type_id_fk" FOREIGN KEY ("event_type_id") REFERENCES "public"."event_type"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "event_type_question" ADD CONSTRAINT "event_type_question_event_type_id_event_type_id_fk" FOREIGN KEY ("event_type_id") REFERENCES "public"."event_type"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "availability_override" ADD CONSTRAINT "availability_override_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "availability_schedule" ADD CONSTRAINT "availability_schedule_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "availability_window" ADD CONSTRAINT "availability_window_schedule_id_availability_schedule_id_fk" FOREIGN KEY ("schedule_id") REFERENCES "public"."availability_schedule"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "calendar_event_cache" ADD CONSTRAINT "calendar_event_cache_connected_calendar_id_connected_calendar_id_fk" FOREIGN KEY ("connected_calendar_id") REFERENCES "public"."connected_calendar"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "connected_calendar" ADD CONSTRAINT "connected_calendar_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "video_connection" ADD CONSTRAINT "video_connection_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking" ADD CONSTRAINT "booking_event_type_id_event_type_id_fk" FOREIGN KEY ("event_type_id") REFERENCES "public"."event_type"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking" ADD CONSTRAINT "booking_host_user_id_user_id_fk" FOREIGN KEY ("host_user_id") REFERENCES "public"."user"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking_answer" ADD CONSTRAINT "booking_answer_booking_id_booking_id_fk" FOREIGN KEY ("booking_id") REFERENCES "public"."booking"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking_answer" ADD CONSTRAINT "booking_answer_question_id_event_type_question_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."event_type_question"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking_guest" ADD CONSTRAINT "booking_guest_booking_id_booking_id_fk" FOREIGN KEY ("booking_id") REFERENCES "public"."booking"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notification_preference" ADD CONSTRAINT "notification_preference_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workflow_job" ADD CONSTRAINT "workflow_job_booking_id_booking_id_fk" FOREIGN KEY ("booking_id") REFERENCES "public"."booking"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "contact_host_idx" ON "contact" USING btree ("host_user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "contact_host_email_idx" ON "contact" USING btree ("host_user_id","email");--> statement-breakpoint
CREATE INDEX "event_type_user_slug_idx" ON "event_type" USING btree ("user_id","slug");--> statement-breakpoint
CREATE INDEX "event_type_user_active_idx" ON "event_type" USING btree ("user_id","is_active");--> statement-breakpoint
CREATE INDEX "availability_override_user_date_idx" ON "availability_override" USING btree ("user_id","date");--> statement-breakpoint
CREATE INDEX "calendar_event_cache_cal_time_idx" ON "calendar_event_cache" USING btree ("connected_calendar_id","start_time","end_time");--> statement-breakpoint
CREATE INDEX "connected_calendar_user_provider_idx" ON "connected_calendar" USING btree ("user_id","provider");--> statement-breakpoint
CREATE INDEX "connected_calendar_status_idx" ON "connected_calendar" USING btree ("status");--> statement-breakpoint
CREATE UNIQUE INDEX "connected_calendar_one_write_target" ON "connected_calendar" USING btree ("user_id") WHERE is_write_target = true;--> statement-breakpoint
CREATE INDEX "booking_host_start_idx" ON "booking" USING btree ("host_user_id","start_time");--> statement-breakpoint
CREATE INDEX "booking_host_status_idx" ON "booking" USING btree ("host_user_id","status");--> statement-breakpoint
CREATE INDEX "booking_invitee_email_idx" ON "booking" USING btree ("invitee_email");--> statement-breakpoint
CREATE INDEX "booking_cancel_token_idx" ON "booking" USING btree ("cancel_token");--> statement-breakpoint
CREATE INDEX "booking_reschedule_token_idx" ON "booking" USING btree ("reschedule_token");--> statement-breakpoint
CREATE INDEX "workflow_job_booking_idx" ON "workflow_job" USING btree ("booking_id");--> statement-breakpoint
CREATE INDEX "workflow_job_singleton_idx" ON "workflow_job" USING btree ("singleton_key");--> statement-breakpoint
CREATE INDEX "workflow_job_status_idx" ON "workflow_job" USING btree ("status");--> statement-breakpoint
CREATE INDEX "user_email_idx" ON "user" USING btree ("email");--> statement-breakpoint
CREATE INDEX "user_username_idx" ON "user" USING btree ("username");--> statement-breakpoint
ALTER TABLE "user" ADD CONSTRAINT "user_username_unique" UNIQUE("username");