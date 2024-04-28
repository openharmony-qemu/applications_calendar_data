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
import LinkedList from '@ohos.util.LinkedList';

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { Observable } from '@ohos/common/src/main/ets/observer/Observable';
import { Observer, ObserverMessage } from '@ohos/common/src/main/ets/observer/Observer';
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
import { BusinessError } from '@ohos.base';

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
  protected isFromMigrate: boolean = false;
  protected logTag: string = TAG;
  private mObserverList: LinkedList<Observer> = new LinkedList();

  constructor(isFromMigrate: boolean = false) {
    this.isFromMigrate = isFromMigrate;
    this.initParas();
    Log.info(this.logTag, `isFromMigrate is ${this.isFromMigrate}`);
  }

  protected initParas() {

  }

  insertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    this.doInsert(rdbStore, uri, values, callback);
  }

  batchInsertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket[],
                             callback: Function) {
    this.doBatchInsert(rdbStore, uri, values, callback);
  }

  insertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    this.doInsert(rdbStore, uri, values, callback);
  }

  batchInsertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket[],
                            callback: Function) {
    this.doBatchInsert(rdbStore, uri, values, callback);
  }

  deleteByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  deleteByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  updateByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    this.doUpdate(rdbStore, uri, values, predicates, callback);
  }

  updateByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    this.doUpdate(rdbStore, uri, values, predicates, callback);
  }

  queryByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    this.doQuery(rdbStore, uri, columns, predicates, callback);
  }

  queryByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
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
  doInsert(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    const table = getTableByUri(uri);
    rdbStore.insert(table, values, (err, rowId) => {
      Log.log(this.logTag, `insert ${table} before callback`);
      callback(err, rowId);
      if (hasNoError(err)) {
        Log.log(this.logTag, `insert ${table} after callback: rowId = ` + rowId);
        if (!this.isFromMigrate) {
          notifyProviderChange(table, OPERATION_INSERT);
          this.notifyAlertsChanges(INSERT_OPERATION_NAME, table, values);
        }
      } else {
        Log.warn(this.logTag, `insert get err:${err?.code}, ${err?.message}`);
      }
    });
  }

  /**
   * 批量插入的公共方法
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 插入的数据
   * @param callback 回调方法
   */
  doBatchInsert(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket[], callback: Function) {
    const table = getTableByUri(uri);
    rdbStore.batchInsert(table, values, (err, rowId) => {
      Log.log(this.logTag, `insert ${table} before callback`);
      callback(err, rowId);
      if (hasNoError(err)) {
        Log.log(this.logTag, `insert ${table} after callback: rowId = ` + rowId);
        if (!this.isFromMigrate) {
          notifyProviderChange(table, OPERATION_INSERT);
          this.notifyAlertsChanges(INSERT_OPERATION_NAME, table, values);
        }
      } else {
        Log.warn(this.logTag, `insert get err:${err?.code}, ${err?.message}`);
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
  doDelete(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const table = getTableByUri(uri);
    rdbStore.delete(table, predicates, (err: BusinessError, count) => {
      Log.log(this.logTag, `delete ${table} before callback`);
      callback(err, count);
      if (hasNoError(err)) {
        Log.log(this.logTag, `delete ${table} after callback: count = ` + count);
        notifyProviderChange(table, OPERATION_DELETE);
        const deleteValue: data_rdb.ValuesBucket = {
          'deleteCounts': count
        }
        Log.log(this.logTag, `deleteValue: [deleteCounts]: ${deleteValue['deleteCounts']}`);
        this.notifyAlertsChanges(DELETE_OPERATION_NAME, table, deleteValue);
      } else {
        Log.error(this.logTag, `delete get err:${err?.code}, ${err?.message}`);
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
  doUpdate(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const table = getTableByUri(uri);
    rdbStore.update(table, values, predicates, (err, count) => {
      Log.log(this.logTag, `update ${table} before callback`);
      callback(err, count);
      if (hasNoError(err)) {
        Log.log(this.logTag, `update ${table} after callback: count = ` + count);
        notifyProviderChange(table, OPERATION_UPDATE);
        this.notifyAlertsChanges(UPDATE_OPERATION_NAME, table, values);
      } else {
        Log.warn(this.logTag, `update get err:${err?.code}, ${err?.message}`);
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
  doQuery(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const table = getTableByUri(uri);
    let queryInnerFun = (err: BusinessError, resultSet: data_rdb.ResultSet) => {
      Log.log(this.logTag, `query ${table} before callback`);
      callback(err, resultSet);
      if (!hasNoError(err)) {
        Log.warn(this.logTag, `query get err:${err?.code}, ${err?.message}`);
      }
    }
    rdbStore.query(table, predicates, columns, queryInnerFun);
  }

  /**
   * 增加一个观察者
   */
  addObserver(observer: Observer) {
    this.mObserverList.add(observer);
  }

  /**
   * 删除一个观察者
   */
  removeObserver(observer: Observer) {
    this.mObserverList.remove(observer);
  }

  /**
   * 被观察者状态发生改变后，通知d订阅的所有观察者更新
   */
  notifyChanges(message: ObserverMessage) {
    this.mObserverList.forEach((observer) => {
      observer.onChange(message);
    })
  }

  notifyAlertsChanges(operationName: string, table: string, values?: data_rdb.ValuesBucket | data_rdb.ValuesBucket[]) {
    let message = new AlertsMessage();
    message.setOperationName(operationName);
    message.setTableName(table);
    if (values) {
      message.setValues(values);
    }
    this.notifyChanges(message);
  }
}
