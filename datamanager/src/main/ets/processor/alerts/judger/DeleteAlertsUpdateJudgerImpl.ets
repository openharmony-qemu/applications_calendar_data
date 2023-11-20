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

import { Log } from '@ohos/common/src/main/ets/utils/Log';

import { CalendarsColumns } from '@ohos/datastructure/src/main/ets/calendars/CalendarsColumns';
import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';
import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';
import relationalStore from '@ohos.data.relationalStore';

const TAG = "DeleteAlarmNeedUpdateJudgerImpl";

/**
 * 在数据表 删除 场景下判断是否需要刷新 alerts
 *
 * @since 2022-09-09
 */
export default class DeleteAlarmNeedUpdateJudgerImpl implements AlertsUpdateJudger {
  // 删除数据的场景下，判断是否删除了四张表的内容
  tableNameSet = new HashSet<string>();

  constructor() {
    this.tableNameSet.add(CalendarsColumns.TABLE_NAME);
    this.tableNameSet.add(EventColumns.TABLE_NAME);
    this.tableNameSet.add(InstancesColumns.TABLE_NAME);
    this.tableNameSet.add(RemindersColumns.TABLE_NAME);
  }

  isNeedToUpdateAlerts(tableName: string, values: relationalStore.ValuesBucket): boolean {
    if (values == null && values == undefined) {
      Log.error(TAG, "this is not a delete operation, please check your Code!");
      return false;
    }
    if (this.tableNameSet.has(tableName)) {
      return true;
    }
    return false;
  }
}