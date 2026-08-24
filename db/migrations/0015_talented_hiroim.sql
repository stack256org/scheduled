CREATE TABLE "rate_limit_bucket" (
	"key" text PRIMARY KEY NOT NULL,
	"count" integer DEFAULT 1 NOT NULL,
	"reset_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE INDEX "rate_limit_bucket_reset_at_idx" ON "rate_limit_bucket" USING btree ("reset_at");--> statement-breakpoint
CREATE INDEX "idempotency_key_expires_at_idx" ON "idempotency_key" USING btree ("expires_at");