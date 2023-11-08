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
import { RemindersColumns } from './RemindersColumns';

interface ReminderIndexesType {
  idIndex: number;
  eventIdIndex: number;
  minutesIndex: number;
  methodIndex: number;
  creatorIndex: number;
  notificationIndex: number;
}

/**
 * the columns indexes for table Reminders
 *
 * @since 2022-10-18
 */
export class RemindersIndexes implements ReminderIndexesType {
  idIndex = 0;
  eventIdIndex = 0;
  minutesIndex = 0;
  methodIndex = 0;
  creatorIndex = 0;
  notificationIndex = 0;
}

/**
 * parse all indexes for table Reminders
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseRemindersIndexes(resultSet: data_rdb.ResultSet): RemindersIndexes | undefined {
  if (resultSet === null || resultSet === undefined) {
    return undefined;
  }
  let indexes: RemindersIndexes = new RemindersIndexes();
  indexes.idIndex = resultSet.getColumnIndex(RemindersColumns.ID);
  indexes.eventIdIndex = resultSet.getColumnIndex(RemindersColumns.EVENT_ID);
  indexes.minutesIndex = resultSet.getColumnIndex(RemindersColumns.MINUTES);
  indexes.methodIndex = resultSet.getColumnIndex(RemindersColumns.METHOD);
  indexes.creatorIndex = resultSet.getColumnIndex(RemindersColumns.CREATOR);
  return indexes;
}