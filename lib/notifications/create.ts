import { notification } from "@/db/schema";
import { db } from "@/lib/db";

export type NotificationType =
  | "booking_created"
  | "booking_cancelled"
  | "booking_rescheduled"
  | "booking_reminder"
  | "booking_pending_approval"
  | "booking_approved"
  | "booking_rejected"
  | "booking_reschedule_requested";

export interface CreateNotificationInput {
  body?: string | null;
  bookingId?: string | null;
  title: string;
  type: NotificationType;
  userId: string;
}

/**
 * Insert an in-app notification (shown in the navbar bell dropdown).
 * Failures are swallowed and logged — a notification must never break the
 * surrounding job/request.
 */
export async function createNotification(input: CreateNotificationInput) {
  try {
    await db.insert(notification).values({
      userId: input.userId,
      type: input.type,
      title: input.title,
      body: input.body ?? null,
      bookingId: input.bookingId ?? null,
    });
  } catch (err) {
    console.error("[createNotification] failed", err);
  }
}
