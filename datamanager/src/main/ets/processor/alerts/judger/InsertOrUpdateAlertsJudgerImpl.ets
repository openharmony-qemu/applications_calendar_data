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

import HashSet from '@ohos.util.HashSet';

import AlertsUpdateJudger from '../AlertsUpdateJudger';

import { CalendarsColumns } from '@ohos/datastructure/src/main/ets/calendars/CalendarsColumns';
import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';
import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';
import relationalStore from '@ohos.data.relationalStore';

/**
 * 在数据表 插入或更新 场景下判断是否需要刷新 alerts
 *
 * @since 2022-09-09
 */
export default class InsertOrUpdateAlertsUpdateJudgerImpl implements AlertsUpdateJudger {
  // 新增或者修改数据的场景下，是否改变了这四张表的相关字段
  tableNameMap = new Map<string, string[]>();

  constructor() {
    this.tableNameMap.set(CalendarsColumns.TABLE_NAME, ['', ''])
    this.tableNameMap.set(EventColumns.TABLE_NAME, ['', '']);
    this.tableNameMap.set(InstancesColumns.TABLE_NAME, ['', '']);
    this.tableNameMap.set(RemindersColumns.TABLE_NAME, ['', '']);
  }

  isNeedToUpdateAlerts(tableName: string, values: relationalStore.ValuesBucket) {
    if (this.tableNameMap.has(tableName)) {
      let rowArray: string[] | undefined = this.tableNameMap.get(tableName);
      let keys: string[] = Object.keys(values);
      let hashSet = new HashSet<string>();
      if (rowArray === null || rowArray === undefined) {
        return false;
      }
      if (keys === null || keys === undefined) {
        return false;
      }

      // 判断对应表中有无相关字段增加
      rowArray.forEach((str) => {
        hashSet.add(str);
      })
      keys.forEach((str) => {
        hashSet.add(str);
      })
      if (rowArray.length + keys.length > hashSet.length) {
        return true;
      }
    }
    return false;
  }
}
