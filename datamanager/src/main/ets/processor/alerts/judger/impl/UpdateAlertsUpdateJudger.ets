/**
 * @file Describe the file
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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


import AlertsUpdateJudger from '../AlertsUpdateJudger';

import { CalendarsColumns } from '@ohos/datastructure/src/main/ets/calendars/CalendarsColumns';
import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';
import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';
import { ValuesBucket } from '@ohos.data.ValuesBucket';

/**
 * 在数据表 插入或更新 场景下判断是否需要刷新 alerts
 *
 * @since 2024-12-09
 */
export default class UpdateAlertsUpdateJudger implements AlertsUpdateJudger {
  private tableNameMap = new Map<string, string[]>();

  constructor() {
    this.tableNameMap.set(CalendarsColumns.TABLE_NAME, ['', ''])
    this.tableNameMap.set(EventColumns.TABLE_NAME, ['', '']);
    this.tableNameMap.set(InstancesColumns.TABLE_NAME, ['', '']);
    this.tableNameMap.set(RemindersColumns.TABLE_NAME, ['', '']);
  }

  public isNeedToUpdateAlerts(tableName: string, values: ValuesBucket): boolean {
    if (this.tableNameMap.has(tableName)) {
      return true;
    }
    return false;
  }
}