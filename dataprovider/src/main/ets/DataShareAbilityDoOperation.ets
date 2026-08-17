/**
 * @file Describe the file
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { Permissions } from '@ohos.privacyManager';
import { AsyncCallback, BusinessError } from '@ohos.base';
import dataShareProxy from './DataShareAbilityAuthenticateProxy';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import dataSharePredicates from '@ohos.data.dataSharePredicates';

const TAG: string = 'DataShareAbilityDoOperation';

const RETRY_TIME_DELAY: number = 50;

let isDatabaseInitializing: boolean = false;

let isDatabaseInitComplete: boolean = false;

class DataShareAbilityDoOperation {
  doInsert(uri: string, value: ValuesBucket, permission: Permissions, callback: AsyncCallback<number>) {
    this.waitDbToRun(() => {
      Log.info(TAG, '[insert] enter');
      try {
        dataShareProxy.insertByProxy(uri, value, permission, (err: BusinessError, id: number) => {
          callback(err, id);
        });
      } catch (err) {
        Log.error(TAG, `err=${err?.message}`);
      }
      Log.info(TAG, '[insert] leave');
    });
  }

  doBatchInsert(uri: string, value: ValuesBucket[], permission: Permissions, callback: AsyncCallback<number>) {
    this.waitDbToRun(() => {
      Log.info(TAG, '[batch insert] enter');
      try {
        dataShareProxy.insertByProxy(uri, value, permission, (err: BusinessError, count: number) => {
          callback(err, count);
        });
      } catch (err) {
        Log.error(TAG, `err=${err?.message}`);
      }
      Log.info(TAG, '[batch insert] leave');
    });
  }

  doDelete(uri: string, predicates: dataSharePredicates.DataSharePredicates, permission: Permissions,
           callback: AsyncCallback<number>) {
    this.waitDbToRun(() => {
      Log.info(TAG, '[delete] enter');
      try {
        dataShareProxy.deleteByProxy(uri, predicates, permission, (err: BusinessError, count: number) => {
          callback(err, count);
        });
      } catch (err) {
        Log.error(TAG, `err=${err?.message}`);
      }
      Log.info(TAG, '[delete] leave');
    });
  }

  doUpdate(uri: string, predicates: dataSharePredicates.DataSharePredicates, value: ValuesBucket,
           permission: Permissions, callback: AsyncCallback<number>) {
    this.waitDbToRun(() => {
      Log.info(TAG, '[update] enter');
      try {
        dataShareProxy.updateByProxy(uri, value, predicates, permission, (err: BusinessError, count: number) => {
          callback(err, count);
        });
      } catch (err) {
        Log.error(TAG, `err=${err?.message}`);
      }
      Log.info(TAG, '[update] leave');
    });
  }

  doQuery(uri: string, predicates: dataSharePredicates.DataSharePredicates, columns: Array<string>,
          permission: Permissions, callback: AsyncCallback<Object>) {
    this.waitDbToRun(() => {
      Log.info(TAG, '[query] enter');
      try {
        dataShareProxy.queryByProxy(uri, columns, predicates, permission, (err: BusinessError, resultSet: Object) => {
          callback(err, resultSet);
        });
      } catch (err) {
        Log.error(TAG, `err=${err?.message}`);
      }
      Log.info(TAG, '[query] leave');
    });
  }

  tryInitDatabase() {
    if (isDatabaseInitializing) {
      return;
    }
    isDatabaseInitializing = true;
    this.initDatabase();
  }

  private async initDatabase() {
    try {
      isDatabaseInitComplete = await dataShareProxy.init();
    } finally {
      isDatabaseInitializing = false;
    }
  }

  private waitDbToRun(runnable: Function) {
    if (isDatabaseInitComplete) {
      runnable();
    } else {
      this.tryInitDatabase();
      setTimeout(() => {
        this.waitDbToRun(runnable);
      }, RETRY_TIME_DELAY);
    }
  }
}

export default new DataShareAbilityDoOperation()