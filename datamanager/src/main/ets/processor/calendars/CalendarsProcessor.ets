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
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { getBundleNameByUri } from '@ohos/common/src/main/ets/utils/UrlUtils';
import {
  CalendarsColumns,
  DEFAULT_CALENDAR_VALUE
} from '@ohos/datastructure/src/main/ets/calendars/CalendarsColumns';
import { DefaultProcessor } from '../DefaultProcessor';
import {
  initValueCreator,
  initPredicateCreator,
  deleteValueCreator,
  initPredicateDefaultAndOwnCreator,
  initPredicateDefaultCalendarProtect
} from '../DatabaseProcessorHelper';

const TAG = 'CalendarsProcessor';

/**
 * the CalendarsProcessor table processor
 *
 * @since 2022-10-17
 */
export class CalendarsProcessor extends DefaultProcessor {
  async insertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    initValueCreator(values, callerName);
    this.doInsert(rdbStore, uri, values, callback);
  }

  async insertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    if (!this.isFromMigrate) {
      const callerName = getBundleNameByUri(uri);
      initValueCreator(values, callerName);
    }
    this.doInsert(rdbStore, uri, values, callback);
  }

  async deleteByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    initPredicateDefaultCalendarProtect(predicates);
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  async deleteByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    initPredicateCreator(predicates, callerName);
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  async updateByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    values = deleteValueCreator(values);
    this.doUpdate(rdbStore, uri, values, predicates, callback);
  }

  async updateByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    values = deleteValueCreator(values);
    initPredicateCreator(predicates, callerName);
    this.doUpdate(rdbStore, uri, values, predicates, callback);
  }

  async queryByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    initPredicateDefaultAndOwnCreator(predicates, callerName);
    this.doQuery(rdbStore, uri, columns, predicates, callback);
  }
}

/**
 * 插入日历存储默认账户
 *
 * @param rdbStore rdb数据库
 * @return 插入的行id
 */
export async function insertDefaultCalendar(rdbStore: data_rdb.RdbStore | null): Promise<number> {
  Log.debug(TAG, `insertDefaultCalendar start`);
  let rowId: number = -1;
  if (!rdbStore) {
    Log.error(TAG, 'insertDefaultCalendar error rdbStore is null');
    return rowId;
  }
  const isOwnDefault = await isExistDefaultCalendar(rdbStore);
  if (isOwnDefault === undefined || isOwnDefault === null || isOwnDefault === true) {
    rowId = -1;
  } else {
    try {
      rowId = await rdbStore.insert(CalendarsColumns.TABLE_NAME, DEFAULT_CALENDAR_VALUE);
      Log.info(TAG, `insertDefaultCalendar succeed , rowId = ${rowId}`);
    } catch (err) {
      Log.error(TAG, 'insertDefaultCalendar error');
    }
  }
  return rowId;
}

/**
 * 检查日历存储的默认账户是否已经存在,account_name is phone, CREATOR is com.huawei.hmos.calendardata
 *
 * @param rdbStore rdb数据库
 * @return true 存在 false 不存在
 */
export async function isExistDefaultCalendar(rdbStore: data_rdb.RdbStore) {
  Log.debug(TAG, `isExistDefaultCalendar start`);
  const columns = [CalendarsColumns.ID, CalendarsColumns.ACCOUNT_NAME, CalendarsColumns.ACCOUNT_TYPE,
    CalendarsColumns.CREATOR];
  let predicates = new dataSharePredicates.DataSharePredicates();
  predicates.equalTo(CalendarsColumns.ACCOUNT_NAME, DEFAULT_CALENDAR_VALUE.account_name);
  predicates.equalTo(CalendarsColumns.CREATOR, DEFAULT_CALENDAR_VALUE.creator);
  try {
    let resultSet = await rdbStore.query(CalendarsColumns.TABLE_NAME, predicates, columns);
    if (resultSet === null || resultSet === undefined) {
      return;
    }
    if (resultSet.rowCount > 0) {
      Log.info(TAG, 'Default Calendar is already exist');
      return true;
    }
  } catch (err) {
    Log.error(TAG, 'Calendars query data error');
  }
  return false;
}
