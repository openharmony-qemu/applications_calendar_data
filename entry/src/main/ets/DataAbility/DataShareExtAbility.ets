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

import Want from '@ohos.app.ability.Want';
import Extension from '@ohos.application.DataShareExtensionAbility';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import relationalStore from '@ohos.data.relationalStore';

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import dataShareProxy from '@ohos/dataprovider/src/main/ets/DataShareAbilityAuthenticateProxy';
import { Permissions } from '@ohos.privacyManager';
import { GlobalThis } from '@ohos/common/src/main/ets/utils/GlobalThis';

const TAG = 'DataShareExtAbility';

let isDatabaseInitializing = false;

let isDatabaseInitComplete = false;

const WRITE_CALENDAR: Permissions = "ohos.permission.WRITE_CALENDAR";
const READ_CALENDAR: Permissions = "ohos.permission.READ_CALENDAR";

export default class DataShareExtAbility extends Extension {
  onCreate(want: Want, callback: Function) {
    Log.info(TAG, '[onCreate] enter');
    try {
      GlobalThis.setExtensionContext(this.context);
      callback();
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[onCreate] leave');
  }

  insert(uri: string, value: relationalStore.ValuesBucket, callback: Function) {
    if (isDatabaseInitComplete) {
      // If the database has been created, perform data operations directly
      this.doInsert(uri, value, callback);
    } else {
      // If the table is not created, try to create the database
      this.tryInitDatabase();
      // Recursively check whether the database is built, per 100ms
      setTimeout(() => {
        this.insert(uri, value, callback);
      }, 100);
    }
  }

 batchInsert(uri: string, value: relationalStore.ValuesBucket[], callback: Function) {
    if (isDatabaseInitComplete) {
      // If the database has been created, perform data operations directly
      this.doBachInsert(uri, value, callback);
    } else {
      // If the table is not created, try to create the database
      this.tryInitDatabase();
      // Recursively check whether the database is built, per 100ms
      setTimeout(() => {
        this.batchInsert(uri, value, callback);
      }, 100);
    }
  }
  
  update(uri: string, predicates: dataSharePredicates.DataSharePredicates, value: relationalStore.ValuesBucket, callback: Function) {
    if (isDatabaseInitComplete) {
      this.doUpdate(uri, predicates, value, callback);
    } else {
      this.tryInitDatabase();
      setTimeout(() => {
        this.update(uri, predicates, value, callback);
      }, 100);
    }
  }

  query(uri: string, predicates: dataSharePredicates.DataSharePredicates, columns: Array<string>, callback: Function) {
    if (isDatabaseInitComplete) {
      this.doQuery(uri, predicates, columns, callback);
    } else {
      this.tryInitDatabase();
      setTimeout(() => {
        this.query(uri, predicates, columns, callback);
      }, 100);
    }
  }

  delete(uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    if (isDatabaseInitComplete) {
      this.doDelete(uri, predicates, callback);
    } else {
      this.tryInitDatabase();
      setTimeout(() => {
        this.delete(uri, predicates, callback);
      }, 100);
    }
  }

  doInsert(uri: string, value: relationalStore.ValuesBucket, callback: Function) {
    Log.info(TAG, '[insert] enter');
    try {
      dataShareProxy.insertByProxy(uri, value, WRITE_CALENDAR, callback);
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[insert] leave');
  }

  doBachInsert(uri: string, value: relationalStore.ValuesBucket[], callback: Function) {
    Log.info(TAG, '[insert] enter');
    try {
      dataShareProxy.insertByProxy(uri, value, WRITE_CALENDAR, callback);
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[insert] leave');
  }

  doDelete(uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    Log.info(TAG, '[delete] enter');
    try {
      dataShareProxy.deleteByProxy(uri, predicates, WRITE_CALENDAR, callback);
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[delete] leave');
  }

  doUpdate(uri: string, predicates: dataSharePredicates.DataSharePredicates, value: relationalStore.ValuesBucket, callback: Function) {
    Log.info(TAG, '[update] enter');
    try {
      dataShareProxy.updateByProxy(uri, value, predicates, WRITE_CALENDAR, callback)
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[update] leave');
  }

  doQuery(uri: string, predicates: dataSharePredicates.DataSharePredicates, columns: Array<string>, callback: Function) {
    Log.info(TAG, '[query] enter');
    try {
      dataShareProxy.queryByProxy(uri, columns, predicates, READ_CALENDAR, callback);
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[query] leave');
  }

  private tryInitDatabase() {
    // If a table is being created, return directly
    if (isDatabaseInitializing) {
      return;
    }
    // Change the status of isDatabaseInitializing
    isDatabaseInitializing = true;
    this.initDatabase();
  }

  async initDatabase() {
    try {
      // Change the status of isDatabaseInitializing and isDatabaseInitComplete
      isDatabaseInitComplete = await dataShareProxy.init();
    } finally {
      isDatabaseInitializing = false;
    }
  }
}