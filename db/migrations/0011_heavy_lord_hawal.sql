ALTER TABLE "user_profile" ADD COLUMN "auto_create_contacts" boolean DEFAULT true NOT NULL;--> statement-breakpoint
ALTER TABLE "user_profile" ADD COLUMN "excluded_contact_domains" text;