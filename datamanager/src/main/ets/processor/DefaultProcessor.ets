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

import LinkedList from '@ohos.util.LinkedList';

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { Observable } from '@ohos/common/src/main/ets/observer/Observable';
import { Observer } from '@ohos/common/src/main/ets/observer/Observer';
import { hasNoError } from '@ohos/common/src/main/ets/utils/ErrorUtils';

import {
  notifyProviderChange,
  OPERATION_INSERT,
  OPERATION_UPDATE,
  OPERATION_DELETE
} from '../commonevents/notify/ProviderChangeNotifier';
import { DatabaseProcessor } from './DatabaseProcessor';
import getTableByUri from '../utils/CalendarUriHelper';
import { AlertsMessage } from './alerts/AlertsMessage';

export const INSERT_OPERATION_NAME = 'insert';

export const UPDATE_OPERATION_NAME = 'update';

export const DELETE_OPERATION_NAME = 'delete';

const TAG = 'DefaultProcessor';


/**
 * the default database Processors
 *
 * @since 2022-06-21
 */
export class DefaultProcessor implements DatabaseProcessor, Observable {
  private mObserverList: LinkedList<Observer> = new LinkedList();

  insertByHighAuthority(rdbStore, uri: string, values, callback) {
    this.doInsert(rdbStore, uri, values, callback);
  }

  insertByLowAuthority(rdbStore, uri: string, values, callback) {
    this.doInsert(rdbStore, uri, values, callback);
  }

  deleteByHighAuthority(rdbStore, uri: string, predicates, callback) {
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  deleteByLowAuthority(rdbStore, uri: string, predicates, callback) {
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  updateByHighAuthority(rdbStore, uri: string, values, predicates, callback) {
    this.doUpdate(rdbStore, uri, values, predicates, callback);
  }

  updateByLowAuthority(rdbStore, uri: string, values, predicates, callback) {
    this.doUpdate(rdbStore, uri, values, predicates, callback);
  }

  queryByHighAuthority(rdbStore, uri: string, columns: Array<string>, predicates, callback) {
    this.doQuery(rdbStore, uri, columns, predicates, callback);
  }

  queryByLowAuthority(rdbStore, uri: string, columns: Array<string>, predicates, callback) {
    this.doQuery(rdbStore, uri, columns, predicates, callback);
  }

  /**
   * 插入的公共方法
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 插入的数据
   * @param callback 回调方法
   */
  doInsert(rdbStore, uri: string, values, callback) {
    const table = getTableByUri(uri);
    rdbStore.insert(table, values, (err, rowId) => {
      Log.log(TAG, `insert ${table} before callback`);
      callback(err, rowId);
      Log.log(TAG, `insert ${table} after callback: rowId = ` + rowId);
      if (hasNoError(err)) {
        notifyProviderChange(table, OPERATION_INSERT);
        this.notifyAlertsChanges(INSERT_OPERATION_NAME, table, values);
      } else {
        Log.warn(TAG, `insert get err:${err?.code}, ${err?.message}`);
      }
    });
  }

  /**
   * 删除的公共方法
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param predicates 删除条件
   * @param callback 回调方法
   */
  doDelete(rdbStore, uri: string, predicates, callback) {
    const table = getTableByUri(uri);
    rdbStore.delete(table, predicates, (err, count) => {
      Log.log(TAG, `delete ${table} before callback`);
      callback(err, count);
      Log.log(TAG, `delete ${table} after callback: count = ` + count);
      if (hasNoError(err)) {
        notifyProviderChange(table, OPERATION_DELETE);
        this.notifyAlertsChanges(DELETE_OPERATION_NAME, table);
      } else {
        Log.warn(TAG, `delete get err:${err?.code}, ${err?.message}`);
      }
    });
  }

  /**
   * 更新的公共方法
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 更新的数据
   * @param predicates 更新条件
   * @param callback 回调方法
   */
  doUpdate(rdbStore, uri: string, values, predicates, callback) {
    const table = getTableByUri(uri);
    rdbStore.update(table, values, predicates, (err, count) => {
      Log.log(TAG, `update ${table} before callback`);
      callback(err, count);
      Log.log(TAG, `update ${table} after callback: count = ` + count);
      if (hasNoError(err)) {
        notifyProviderChange(table, OPERATION_UPDATE);
        this.notifyAlertsChanges(UPDATE_OPERATION_NAME, table, values);
      } else {
        Log.warn(TAG, `update get err:${err?.code}, ${err?.message}`);
      }
    });
  }

  /**
   * 查询的公共方法
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param columns 查询的列名
   * @param predicates 查询条件
   * @param callback 回调方法
   */
  doQuery(rdbStore, uri: string, columns: Array<string>, predicates, callback) {
    const table = getTableByUri(uri);
    rdbStore.query(table, predicates, columns, function (err, resultSet) {
      Log.log(TAG, `query ${table} before callback`);
      callback(err, resultSet);
      Log.log(TAG, `query ${table} after callback: resultSet.rowCount = ` + resultSet.rowCount);
      if (!hasNoError(err)) {
        Log.warn(TAG, `update get err:${err?.code}, ${err?.message}`);
      }
    });
  }

  /**
   * 增加一个观察者
   */
  addObserver(observer) {
    this.mObserverList.add(observer);
  }

  /**
   * 删除一个观察者
   */
  removeObserver(observer) {
    this.mObserverList.remove(observer);
  }

  /**
   * 被观察者状态发生改变后，通知d订阅的所有观察者更新
   */
  notifyChanges(message) {
    this.mObserverList.forEach((observer) => {
      observer.onChange(message);
    })
  }

  notifyAlertsChanges(operationName: string, table: string, values?) {
    let message = new AlertsMessage();
    message.setOperationName(operationName);
    message.setTableName(table);
    message.setValues(values);
    this.notifyChanges(message);
  }
}
