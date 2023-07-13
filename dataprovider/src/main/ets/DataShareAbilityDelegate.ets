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

import { Log } from '@ohos/common/src/main/ets/utils/Log';

import { insertDefaultCalendar } from '@ohos/datamanager/src/main/ets/processor/calendars/CalendarsProcessor';
import CalendarDataHelper from '@ohos/datamanager/src/main/ets/utils/CalendarDataHelper';
import getTableByUri from '@ohos/datamanager/src/main/ets/utils/CalendarUriHelper';
import factory from '@ohos/datamanager/src/main/ets/processor/DatabaseProcessorFactory';

let rdbStore;
let TAG = "DataShareAbilityDelegate";

/**
 * the delegate of CalendarData's DatabaseProcessor
 *
 * @since 2022-06-15
 */
export default {
  async init(): Promise<boolean> {
    Log.info(TAG, 'init start');
    try {
      rdbStore = await CalendarDataHelper.getInstance().getRdbStore();
      await insertDefaultCalendar(rdbStore);
    } catch (err) {
      Log.error(TAG, 'init err');
      return false;
    }
    Log.info(TAG, 'init end');
    return true;
  },

  insertByHighAuthority(uri, value, callback) {
    Log.info(TAG, `insert uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `insert table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.insertByHighAuthority(rdbStore, uri, value, callback);
      return;
    } else {
      Log.error(TAG, 'insert with invalid processor');
    }
  },

  insertByLowAuthority(uri: string, value, callback) {
    Log.info(TAG, `insert uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `insert table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.insertByLowAuthority(rdbStore, uri, value, callback);
      return;
    } else {
      Log.error(TAG, 'insert with invalid processor');
    }
  },

  deleteByHighAuthority(uri, predicates, callback) {
    Log.info(TAG, `delete uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `delete table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.deleteByHighAuthority(rdbStore, uri, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'delete with invalid processor');
    }
  },

  deleteByLowAuthority(uri, predicates, callback) {
    Log.info(TAG, `delete uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `delete table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.deleteByLowAuthority(rdbStore, uri, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'delete with invalid processor');
    }
  },

  updateByHighAuthority(uri, value, predicates, callback) {
    Log.info(TAG, `update uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `update table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.updateByHighAuthority(rdbStore, uri, value, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'update with invalid processor');
    }
  },

  updateByLowAuthority(uri, value, predicates, callback) {
    Log.info(TAG, `update uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `update table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.updateByLowAuthority(rdbStore, uri, value, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'update with invalid processor');
    }
  },


  queryByHighAuthority(uri, columns, predicates, callback) {
    Log.info(TAG, `query uri: ${uri}`);
    const table = getTableByUri(uri);
    Log.info(TAG, `query table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.queryByHighAuthority(rdbStore, uri, columns, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'query with invalid processor');
    }
  },

  queryByLowAuthority(uri, columns, predicates, callback) {
    Log.info(TAG, `query uri: ${uri}`);
    const table = getTableByUri(uri);
    Log.info(TAG, `query table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.queryByLowAuthority(rdbStore, uri, columns, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'query with invalid processor');
    }
  }
}