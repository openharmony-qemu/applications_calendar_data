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
import { ObserverMessage } from '@ohos/common/src/main/ets/observer/Observer';

/**
 * the Alerts Message, It is used to describe the scenario where the alerts table needs to be updated
 *
 * @since 2022-09-09
 */
export class AlertsMessage extends ObserverMessage {
  private mOperationName: string;
  private mTableName: string;
  private mValues: data_rdb.ValuesBucket | data_rdb.ValuesBucket[];

  constructor() {
    super();
    this.mOperationName = '';
    this.mTableName = '';
    this.mValues = {};
  }

  setOperationName(mOperationName: string) {
    this.mOperationName = mOperationName;
  }

  setTableName(mTableName: string) {
    this.mTableName = mTableName;
  }

  setValues(mValues: data_rdb.ValuesBucket | data_rdb.ValuesBucket[]) {
    this.mValues = mValues;
  }

  getOperationName(): string {
    return this.mOperationName;
  }

  getTableName(): string {
    return this.mTableName;
  }

  getValues(): data_rdb.ValuesBucket | data_rdb.ValuesBucket[] {
    return this.mValues;
  }
}