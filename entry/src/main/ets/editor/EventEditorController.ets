/* Copyright (c) 2026 Harmony Contrib. SPDX-License-Identifier: Apache-2.0 */
import calendarManager from '@ohos.calendarManager';
import common from '@ohos.app.ability.common';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';

// A new event is written only after the user presses Save in this session.
// The caller cannot select an existing ID or send a command that saves a form.
export class EventEditorController {
  public event: calendarManager.Event;
  public eventId: number = -1;
  public error: string = '';
  private active: boolean = true;
  private busy: boolean = false;
  private finishing: boolean = false;

  private context: common.Context;
  private session: UIExtensionContentSession;

  constructor(context: common.Context, session: UIExtensionContentSession, serialized: string) {
    this.context = context;
    this.session = session;
    if (typeof serialized !== 'string' || serialized.length > 65536) {
      throw new Error('Invalid event data');
    }
    const event: calendarManager.Event = JSON.parse(serialized) as calendarManager.Event;
    if (event === null || typeof event !== 'object' || Array.isArray(event) ||
      event.type !== calendarManager.EventType.NORMAL || event.id !== undefined ||
      event.instanceStartTime !== undefined || event.instanceEndTime !== undefined ||
      event.identifier !== undefined || event.attendee !== undefined || event.service !== undefined ||
      event.isLunar !== undefined || event.timeZone !== undefined ||
      !Number.isSafeInteger(event.startTime) || !Number.isSafeInteger(event.endTime) ||
      event.startTime < 0 || event.endTime > 8640000000000000 || event.endTime <= event.startTime ||
      (event.title !== undefined && (typeof event.title !== 'string' || event.title.length > 5000)) ||
      (event.description !== undefined && (typeof event.description !== 'string' || event.description.length > 5000))) {
      throw new Error('Invalid or unsupported event fields');
    }
    this.event = event;
  }

  public dispose(): void {
    this.active = false;
  }

  public async save(title: string, start: string, end: string, description: string): Promise<void> {
    if (!this.active || this.busy || this.finishing) {
      return;
    }
    this.busy = true;
    this.error = '';
    try {
      // A failed result delivery may be retried without inserting a duplicate.
      if (this.eventId < 0) {
        const startTime: number = Date.parse(start);
        const endTime: number = Date.parse(end);
        if (title.length > 5000 || description.length > 5000 || !Number.isSafeInteger(startTime) ||
          !Number.isSafeInteger(endTime) || startTime < 0 || endTime <= startTime) {
          throw new Error('请检查标题、开始时间和结束时间');
        }
        const event: calendarManager.Event = {
          type: calendarManager.EventType.NORMAL,
          title: title,
          startTime: startTime,
          endTime: endTime,
          description: description,
          isAllDay: this.event.isAllDay,
          location: this.event.location,
          reminderTime: this.event.reminderTime,
          recurrenceRule: this.event.recurrenceRule
        };
        const manager: calendarManager.CalendarManager = calendarManager.getCalendarManager(this.context);
        const calendar: calendarManager.Calendar = await manager.getCalendar();
        // Host/caller death before the write starts is cancellation, not consent.
        if (!this.active) {
          return;
        }
        const id: number = await calendar.addEvent(event);
        if (!Number.isInteger(id) || id <= 0 || id > 2147483647) {
          throw new Error('日历服务没有返回有效的日程编号');
        }
        this.eventId = id;
      }
      // If the host died during a user-confirmed commit, do not report success
      // to a destroyed session. The committed user event remains in the calendar.
      if (this.active) {
        await this.finish(this.eventId);
      }
    } catch (error) {
      this.error = `保存失败：${error?.message ?? '日历服务不可用'}`;
    } finally {
      this.busy = false;
    }
  }

  public async cancel(): Promise<void> {
    if (!this.active || this.busy || this.finishing) {
      return;
    }
    this.error = '';
    try {
      await this.finish(this.eventId);
    } catch (error) {
      this.error = `关闭失败：${error?.message ?? '请重试'}`;
    }
  }

  private async finish(eventId: number): Promise<void> {
    this.finishing = true;
    try {
      await this.session.terminateSelfWithResult({
        resultCode: 0,
        want: { parameters: { eventId: eventId } }
      });
      this.active = false;
    } finally {
      this.finishing = false;
    }
  }
}
