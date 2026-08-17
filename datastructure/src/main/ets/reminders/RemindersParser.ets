/**
 * @file Describe the file
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import data_rdb from '@ohos.data.relationalStore';

import { Reminders } from './Reminders';
import { RemindersColumns } from './RemindersColumns';

/**
 * parse all columns for table Reminders
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseReminders(resultSet: data_rdb.ResultSet): Reminders | undefined {
  if ((resultSet === null) || (resultSet === undefined)) {
    return undefined;
  }
  let reminders: Reminders = new Reminders();
  let dataResult: data_rdb.ValuesBucket = resultSet.getRow();
  reminders.id = dataResult[RemindersColumns.ID] as number ?? reminders.id;
  reminders.eventId = dataResult[RemindersColumns.EVENT_ID] as number ?? reminders.eventId;
  reminders.minutes = dataResult[RemindersColumns.MINUTES] as number ?? reminders.minutes;
  reminders.method = dataResult[RemindersColumns.METHOD] as number ?? reminders.method;
  reminders.creator = dataResult[RemindersColumns.CREATOR] as string ?? reminders.creator;
  reminders.reminderUuid = dataResult[RemindersColumns.REMINDER_UUID] as string ?? reminders.reminderUuid;
  reminders.eventUuid = dataResult[RemindersColumns.EVENT_UUID] as string ?? reminders.eventUuid;
  return reminders;
}