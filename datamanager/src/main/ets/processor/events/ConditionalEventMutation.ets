/* Copyright (c) 2026 Harmony Contrib. SPDX-License-Identifier: Apache-2.0 */
import rdb from '@ohos.data.relationalStore';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import util from '@ohos.util';
import { BusinessError } from '@ohos.base';

export const MUTATION_KIND: string = '__calendarMutationKind';
export const MUTATION_ID: string = '__calendarMutationId';
export const MUTATION_REVISION: string = '__calendarMutationExpectedRevision';
export const MUTATION_REMINDERS: string = '__calendarMutationReminders';
export const MUTATION_COLUMN: string = 'calendarMutationRevision';

export interface ConditionalMutationResult {
  id: number;
  count: number;
  operation: string;
}

class CalendarConditionalMutationParameterError extends Error implements BusinessError {
  code: number;
  constructor(message: string) {
    super(message);
    this.code = 401;
    this.name = 'CalendarConditionalMutationParameterError';
  }
}

function invalid(message: string): CalendarConditionalMutationParameterError {
  return new CalendarConditionalMutationParameterError(message);
}

/** Invoked only after the existing DataShare authentication and creator filter. */
export async function mutateEventConditionally(store: rdb.RdbStore, values: rdb.ValuesBucket,
  authorizedPredicates: dataSharePredicates.DataSharePredicates): Promise<ConditionalMutationResult> {
  const operation = values[MUTATION_KIND] as string;
  const id = values[MUTATION_ID] as number;
  const revision = values[MUTATION_REVISION] as string;
  const allowed = [MUTATION_KIND, MUTATION_ID, MUTATION_REVISION];
  if (operation === 'update') {
    allowed.push('title', 'dtstart', 'dtend', 'description', MUTATION_REMINDERS);
  }
  if (!['update', 'delete'].includes(operation) || !Number.isSafeInteger(id) || id <= 0 || id > 2147483647 ||
    typeof revision !== 'string' || !/^(0|[1-9][0-9]{0,15})$/.test(revision) ||
    !Number.isSafeInteger(Number(revision)) || Object.keys(values).some((key: string) => !allowed.includes(key))) {
    throw invalid('Invalid conditional Calendar mutation');
  }
  const changes: rdb.ValuesBucket = {};
  let reminders: number[] = [];
  if (operation === 'update') {
    const title = values['title'] as string;
    const description = values['description'] as string;
    const start = values['dtstart'] as number;
    const end = values['dtend'] as number;
    const reminderText = values[MUTATION_REMINDERS] as string;
    if (typeof title !== 'string' || title.trim().length === 0 || title.length > 5000 ||
      typeof description !== 'string' || description.length > 5000 || !Number.isSafeInteger(start) ||
      !Number.isSafeInteger(end) || start < 0 || end <= start || end > 8640000000000000 ||
      typeof reminderText !== 'string' || (reminderText !== '' && !/^(0|[1-9][0-9]{0,4})$/.test(reminderText)) ||
      (reminderText !== '' && Number(reminderText) > 10080)) {
      throw invalid('Invalid conditional Calendar edit fields');
    }
    if (reminderText !== '') { reminders = [Number(reminderText)]; }
    changes['title'] = title; changes['description'] = description;
    changes['dtstart'] = start; changes['dtend'] = end;
  }

  // The original low-authority creator predicate is evaluated by the real
  // provider. No fixture or privileged helper opens this database.
  const authorized = await store.query('Events', authorizedPredicates,
    ['_id', 'calendar_id', 'creator', MUTATION_COLUMN]);
  let calendarId: number = 0;
  let creator: string = '';
  try {
    if (authorized.rowCount === 0) { return { id: id, count: 0, operation: operation }; }
    if (authorized.rowCount !== 1 || !authorized.goToFirstRow() ||
      authorized.getLong(authorized.getColumnIndex('_id')) !== id) {
      throw invalid('Conditional Calendar predicate must identify one exact revision');
    }
    if (authorized.getLong(authorized.getColumnIndex(MUTATION_COLUMN)).toString() !== revision) {
      return { id: id, count: 0, operation: operation };
    }
    calendarId = authorized.getLong(authorized.getColumnIndex('calendar_id'));
    creator = authorized.getString(authorized.getColumnIndex('creator'));
  } finally { authorized.close(); }

  const tx = await store.createTransaction({ transactionType: rdb.TransactionType.IMMEDIATE });
  let finished: boolean = false;
  try {
    const exact = new rdb.RdbPredicates('Events').equalTo('_id', id).equalTo('calendar_id', calendarId)
      .equalTo('creator', creator).equalTo(MUTATION_COLUMN, Number(revision));
    const actual = await tx.query(exact,
      ['_id', 'uuid', 'important_event_type', 'allDay', 'event_calendar_type', 'rrule', 'rdate', 'exrule', 'exdate']);
    let uuid: string = '';
    try {
      if (actual.rowCount === 0) {
        await tx.rollback(); finished = true;
        return { id: id, count: 0, operation: operation };
      }
      if (actual.rowCount !== 1 || !actual.goToFirstRow()) { throw invalid('Ambiguous Calendar revision'); }
      // The product editor remains restricted to ordinary timed non-recurring
      // events. Rich event and relation fields are preserved, never rewritten.
      for (const column of ['important_event_type', 'allDay', 'event_calendar_type']) {
        if (actual.getLong(actual.getColumnIndex(column)) !== 0) { throw invalid('Read-only Calendar event'); }
      }
      for (const column of ['rrule', 'rdate', 'exrule', 'exdate']) {
        const index = actual.getColumnIndex(column);
        if (!actual.isColumnNull(index) && actual.getString(index) !== '') { throw invalid('Read-only recurring event'); }
      }
      uuid = actual.getString(actual.getColumnIndex('uuid'));
    } finally { actual.close(); }
    const reminderPredicate = new rdb.RdbPredicates('Reminders').equalTo('event_id', id);
    const oldReminders = await tx.query(reminderPredicate, ['_id']);
    try { if (oldReminders.rowCount > 1) { throw invalid('Read-only multiple-reminder event'); } }
    finally { oldReminders.close(); }
    let count: number;
    if (operation === 'delete') {
      count = await tx.delete(exact); // Existing event cleanup triggers cover all child tables.
    } else {
      count = await tx.update(changes, exact);
      if (count !== 1) { throw invalid('Conditional Calendar update lost its revision'); }
      await tx.delete(reminderPredicate);
      for (const minutes of reminders) {
        const inserted = await tx.insert('Reminders', { event_id: id, minutes: minutes, creator: creator,
          reminder_uuid: util.generateRandomUUID(), event_uuid: uuid });
        if (inserted <= 0) { throw invalid('Conditional Calendar reminder insert failed'); }
      }
    }
    if (count !== 1) { throw invalid('Conditional Calendar mutation affected unexpected rows'); }
    await tx.commit(); finished = true;
    return { id: id, count: count, operation: operation };
  } catch (error) {
    if (!finished) { await tx.rollback(); }
    throw error as Error; // Actual RDB/provider errors must not become stale=false.
  }
}
