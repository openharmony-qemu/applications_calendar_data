/**
 * @file Describe the file
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { ValuesBucket } from '@ohos.data.ValuesBucket';

import { Log } from '@ohos/common/src/main/ets/utils/Log';

import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';
import { parseReminders } from '@ohos/datastructure/src/main/ets/reminders/RemindersParser';
import { Reminders } from '@ohos/datastructure/src/main/ets/reminders/Reminders';

const TAG = 'RemindersManager';

/**
 * 查询reminders表
 * @param rdbStore rdb数据库
 * @param predicates 查询条件
 * @return Reminders[] 查询结果
 */
export async function queryReminders(rdbStore: data_rdb.RdbStore, predicates: dataSharePredicates.DataSharePredicates):
  Promise<Reminders[] | undefined> {
  const columns: string[] = [
    RemindersColumns.ID,
    RemindersColumns.EVENT_ID,
    RemindersColumns.MINUTES,
    RemindersColumns.REMINDER_UUID,
    RemindersColumns.EVENT_UUID
  ];
  let resultSet: data_rdb.ResultSet | null = null;
  let reminders: Reminders[] = [];
  try {
    resultSet = await rdbStore.query(RemindersColumns.TABLE_NAME, predicates, columns);
    if ((resultSet === null) || (resultSet === undefined)) {
      return;
    }
    if (!resultSet.goToFirstRow()) {
      return;
    }
    do {
      const reminder = parseReminders(resultSet) as Reminders;
      reminders.push(reminder);
    } while (resultSet.goToNextRow());
  } catch (err) {
    Log.error(TAG, `queryReminder catch error = ${err?.message},${err?.code}`);
    return;
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  return reminders;
}