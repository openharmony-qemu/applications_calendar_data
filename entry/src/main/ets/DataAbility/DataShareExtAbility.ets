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

import Extension from '@ohos.application.DataShareExtensionAbility'

import { Log } from '@ohos/common/src/main/ets/utils/Log'

import dataShareProxy from '@ohos/dataprovider/src/main/ets/DataShareAbilityAuthenticateProxy'

const TAG = 'DataShareExtAbility'

let isDatabaseInitializing = false;

let isDatabaseInitComplete = false;

export default class DataShareExtAbility extends Extension {
  onCreate(want, callback) {
    Log.info(TAG, '[onCreate] enter');
    try {
      globalThis.extensionContext = this.context;
      callback();
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[onCreate] leave');
  }

  insert(uri, value, callback) {
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

  update(uri, predicates, value, callback) {
    if (isDatabaseInitComplete) {
      this.doUpdate(uri, predicates, value, callback);
    } else {
      this.tryInitDatabase();
      setTimeout(() => {
        this.update(uri, predicates, value, callback);
      }, 100);
    }
  }

  query(uri, predicates, columns, callback) {
    if (isDatabaseInitComplete) {
      this.doQuery(uri, predicates, columns, callback);
    } else {
      this.tryInitDatabase();
      setTimeout(() => {
        this.query(uri, predicates, columns, callback);
      }, 100);
    }
  }

  delete(uri, predicates, callback) {
    if (isDatabaseInitComplete) {
      this.doDelete(uri, predicates, callback);
    } else {
      this.tryInitDatabase();
      setTimeout(() => {
        this.delete(uri, predicates, callback);
      }, 100);
    }
  }

  doInsert(uri, value, callback) {
    Log.info(TAG, '[insert] enter');
    try {
      dataShareProxy.insertByProxy(uri, value, callback);
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[insert] leave');
  }

  doDelete(uri, predicates, callback) {
    Log.info(TAG, '[delete] enter');
    try {
      dataShareProxy.deleteByProxy(uri, predicates, callback);
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[delete] leave');
  }

  doUpdate(uri, predicates, value, callback) {
    Log.info(TAG, '[update] enter');
    try {
      dataShareProxy.updateByProxy(uri, value, predicates, callback)
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[update] leave');
  }

  doQuery(uri, predicates, columns, callback) {
    Log.info(TAG, '[query] enter');
    try {
      dataShareProxy.queryByProxy(uri, columns, predicates, callback);
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