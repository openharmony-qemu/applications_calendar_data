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
import data_rdb from '@ohos.data.relationalStore';
import dataSharePredicates from '@ohos.data.dataSharePredicates';

let rdbStore: data_rdb.RdbStore;
let TAG = "DataShareAbilityDelegate";

/**
 * the delegate of CalendarData's DatabaseProcessor
 *
 * @since 2022-06-15
 */
class DataShareAbilityDelegate {
  async init(): Promise<boolean> {
    Log.info(TAG, 'init start');
    try {
      rdbStore = await CalendarDataHelper.getInstance().getRdbStore() as data_rdb.RdbStore;
      await insertDefaultCalendar(rdbStore);
    } catch (err) {
      Log.error(TAG, 'init err');
      return false;
    }
    Log.info(TAG, 'init end');
    return true;
  }

  insertByHighAuthority(uri: string, value: data_rdb.ValuesBucket, callback: Function) {
    if (!rdbStore) {
      this.getDb();
      Log.warn(TAG, `insertByHighAuthority uri: ${uri} rdbStore is null`)
      return;
    }
    Log.info(TAG, `insertByHighAuthority uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `insertByHighAuthority table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.insertByHighAuthority(rdbStore, uri, value, callback);
      return;
    } else {
      Log.error(TAG, 'insertByHighAuthority with invalid processor');
    }
  }

  batchInsertByHighAuthority(uri: string, value: data_rdb.ValuesBucket[], callback: Function) {
    if (!rdbStore) {
      this.getDb();
      Log.warn(TAG, `insert uri: ${uri} rdbStore is null`)
      return;
    }
    Log.info(TAG, `insert uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `insert table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.batchInsertByHighAuthority(rdbStore, uri, value, callback);
      return;
    } else {
      Log.error(TAG, 'insert with invalid processor');
    }
  }

  async getDb() {
    rdbStore = await CalendarDataHelper.getInstance().getRdbStore() as data_rdb.RdbStore;
  }

  insertByLowAuthority(uri: string, value: data_rdb.ValuesBucket, callback: Function) {
    if (!rdbStore) {
      Log.warn(TAG, `insertByLowAuthority uri: ${uri} rdbStore is null`)
      this.getDb();
      return;
    }
    Log.info(TAG, `insertByLowAuthority uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `insertByLowAuthority table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.insertByLowAuthority(rdbStore, uri, value, callback);
      return;
    } else {
      Log.error(TAG, 'insertByLowAuthority with invalid processor');
    }
  }

  batchInsertByLowAuthority(uri: string, value: data_rdb.ValuesBucket[], callback: Function) {

    if (!rdbStore) {
      Log.warn(TAG, `insert uri: ${uri} rdbStore is null`)
      this.getDb();
      return;
    }
    Log.info(TAG, `insert uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `insert table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.batchInsertByLowAuthority(rdbStore, uri, value, callback);
      return;
    } else {
      Log.error(TAG, 'insert with invalid processor');
    }
  }

  deleteByHighAuthority(uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    if (!rdbStore) {
      this.getDb();
      Log.warn(TAG, `deleteByHighAuthority uri: ${uri} rdbStore is null`)
      return;
    }
    Log.info(TAG, `deleteByHighAuthority uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `deleteByHighAuthority table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.deleteByHighAuthority(rdbStore, uri, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'deleteByHighAuthority with invalid processor');
    }
  }

  deleteByLowAuthority(uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    if (!rdbStore) {
      this.getDb();
      Log.warn(TAG, `deleteByLowAuthority uri: ${uri} rdbStore is null`)
      return;
    }
    Log.info(TAG, `deleteByLowAuthority uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `deleteByLowAuthority table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.deleteByLowAuthority(rdbStore, uri, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'deleteByLowAuthority with invalid processor');
    }
  }

  updateByHighAuthority(uri: string, value: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    if (!rdbStore) {
      this.getDb();
      Log.warn(TAG, `updateByHighAuthority uri: ${uri} rdbStore is null`)
      return;
    }
    Log.info(TAG, `updateByHighAuthority uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `updateByHighAuthority table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.updateByHighAuthority(rdbStore, uri, value, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'updateByHighAuthority with invalid processor');
    }
  }

  updateByLowAuthority(uri: string, value: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    if (!rdbStore) {
      this.getDb();
      Log.warn(TAG, `updateByLowAuthority uri: ${uri} rdbStore is null`)
      return;
    }
    Log.info(TAG, `updateByLowAuthority uri: ${uri}`);
    let table = getTableByUri(uri);
    Log.info(TAG, `updateByLowAuthority table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.updateByLowAuthority(rdbStore, uri, value, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'updateByLowAuthority with invalid processor');
    }
  }

  queryByHighAuthority(uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    if (!rdbStore) {
      this.getDb();
      Log.warn(TAG, `queryByHighAuthority uri: ${uri} rdbStore is null`)
      return;
    }
    Log.info(TAG, `queryByHighAuthority uri: ${uri}`);
    const table = getTableByUri(uri);
    Log.info(TAG, `queryByHighAuthority table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.queryByHighAuthority(rdbStore, uri, columns, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'queryByHighAuthority with invalid processor');
    }
  }

  queryByLowAuthority(uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    if (!rdbStore) {
      this.getDb();
      Log.warn(TAG, `queryByLowAuthority uri: ${uri} rdbStore is null`)
      return;
    }
    Log.info(TAG, `queryByLowAuthority uri: ${uri}`);
    const table = getTableByUri(uri);
    Log.info(TAG, `queryByLowAuthority table: ${table}`);

    const processor = factory.getDatabaseProcessor(table);
    if (processor !== null && processor !== undefined) {
      processor.queryByLowAuthority(rdbStore, uri, columns, predicates, callback);
      return;
    } else {
      Log.error(TAG, 'queryByLowAuthority with invalid processor');
    }
  }
}

export default new DataShareAbilityDelegate()