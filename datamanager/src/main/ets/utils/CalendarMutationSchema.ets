/* Copyright (c) 2026 Harmony Contrib. SPDX-License-Identifier: Apache-2.0 */
import rdb from '@ohos.data.relationalStore';

const COLUMN: string = 'calendarMutationRevision';
const CLOCK: string = 'CalendarMutationClock';
const MAX_REVISION: number = 9007199254740990;

/** Additive migration for both an existing provider DB and a newly created DB. */
export async function ensureCalendarMutationSchema(store: rdb.RdbStore): Promise<void> {
  const columns = await store.querySql('PRAGMA table_info(Events)');
  let exists: boolean = false;
  try {
    while (columns.goToNextRow()) {
      if (columns.getString(columns.getColumnIndex('name')) !== COLUMN) { continue; }
      if (exists || columns.getString(columns.getColumnIndex('type')).toUpperCase() !== 'INTEGER' ||
        columns.getLong(columns.getColumnIndex('notnull')) !== 1 ||
        columns.getString(columns.getColumnIndex('dflt_value')) !== '0') {
        throw new Error('Incompatible Calendar mutation revision schema');
      }
      exists = true;
    }
  } finally { columns.close(); }
  if (!exists) {
    await store.executeSql(`ALTER TABLE Events ADD COLUMN ${COLUMN} INTEGER NOT NULL DEFAULT 0`);
  }
  await store.executeSql(`CREATE TABLE IF NOT EXISTS ${CLOCK} ` +
    '(singleton INTEGER PRIMARY KEY CHECK(singleton = 1), value INTEGER NOT NULL CHECK(value >= 0))');
  await store.executeSql(`INSERT OR IGNORE INTO ${CLOCK}(singleton, value) VALUES(1, 0)`);
  await store.executeSql(`CREATE TRIGGER IF NOT EXISTS calendar_mutation_clock_bound BEFORE UPDATE ON ${CLOCK} ` +
    `WHEN OLD.value >= ${MAX_REVISION} BEGIN SELECT RAISE(ABORT, 'Calendar revision exhausted'); END`);
  const advance = `UPDATE ${CLOCK} SET value = value + 1 WHERE singleton = 1; `;
  const assignNew = `UPDATE Events SET ${COLUMN} = (SELECT value FROM ${CLOCK} WHERE singleton = 1) ` +
    'WHERE _id = NEW._id; ';
  await store.executeSql('CREATE TRIGGER IF NOT EXISTS calendar_mutation_event_insert AFTER INSERT ON Events ' +
    `BEGIN ${advance}${assignNew}END`);
  await store.executeSql('CREATE TRIGGER IF NOT EXISTS calendar_mutation_event_update AFTER UPDATE ON Events ' +
    `WHEN NEW.${COLUMN} = OLD.${COLUMN} BEGIN ${advance}${assignNew}END`);
  // These triggers execute in the SAME SQLite transaction as the real relation
  // write. Failed or rolled-back mutations also roll back clock and revision.
  // Using a provider-wide persistent clock prevents delete/reinsert ABA even
  // when a raw DataShare client supplies an old event ID or UUID.
  for (const table of ['Attendees', 'Reminders']) {
    const key = 'event_id';
    for (const operation of ['INSERT', 'UPDATE', 'DELETE']) {
      let body: string = '';
      if (operation !== 'INSERT') {
        body += `UPDATE Events SET ${COLUMN} = ${COLUMN} WHERE _id = OLD.${key}; `;
      }
      if (operation !== 'DELETE') {
        body += `UPDATE Events SET ${COLUMN} = ${COLUMN} WHERE _id = NEW.${key}; `;
      }
      await store.executeSql(`CREATE TRIGGER IF NOT EXISTS calendar_mutation_${table}_${operation} ` +
        `AFTER ${operation} ON ${table} BEGIN ${body}END`);
    }
  }
}
