/* Copyright (c) 2026 Harmony Contrib. SPDX-License-Identifier: Apache-2.0 */
import calendarManager from '@ohos.calendarManager';

export interface CalendarEventSnapshot {
  event: calendarManager.Event;
  revision: string;
}

/** Additive native product methods; this is a declaration, never a JS fallback.
 * updateEventIfUnchanged changes only title/start/end/description/reminderTime.
 * All other persisted Event and attendee/service/location fields are preserved.
 * Existing rich-event and multiple-reminder items remain read-only here.
 */
export interface AtomicCalendar extends calendarManager.Calendar {
  getEventSnapshot(id: number): Promise<CalendarEventSnapshot>;
  updateEventIfUnchanged(revision: string, fields: calendarManager.Event): Promise<boolean>;
  deleteEventIfUnchanged(revision: string, id: number): Promise<boolean>;
}
