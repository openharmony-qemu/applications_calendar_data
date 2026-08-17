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

import ohosDataRdb from '@ohos.data.relationalStore';
import data_rdb from '@ohos.data.relationalStore';
import { dataSharePredicates } from '@kit.ArkData';
import { Log } from '@ohos/common';
import { AsyncCallback } from '@kit.BasicServicesKit';

const TAG: string = 'RdbStoreHelper';

/**
 * rdb数据库操作
 *
 * @since 2024-04-27
 */
export class RdbStoreHelper {
  /**
   * 查询
   *
   * @param rdbStore  数据库
   * @param tableName 表名
   * @param predicates 查询条件
   * @returns 查询结果
   */
  public static async query(rdbStore: ohosDataRdb.RdbStore, tableName: string,
                            predicates: dataSharePredicates.DataSharePredicates,
                            columns?: string[]): Promise<data_rdb.ResultSet | null> {
    try {
      return rdbStore.query(tableName, predicates, columns);
    } catch (err) {
      Log.error(TAG, `query tableName:${tableName} error: ${err?.code}, ${err?.message}`);
    }
    return null;
  }

  /**
   * 刪除
   *
   * @param rdbStore 数据库链接
   * @param tableName 表名
   * @param predicates 条件
   */
  public static async delete(rdbStore: ohosDataRdb.RdbStore, tableName: string,
                             predicates: dataSharePredicates.DataSharePredicates): Promise<number> {
    try {
      return await rdbStore.delete(tableName, predicates);
    } catch (err) {
      Log.error(TAG, `delete tableName:${tableName} error: ${err?.code}, ${err?.message}`);
    }
    return 0;
  }

  /**
   * 批量插入
   *
   * @param rdbStore 数据库链接
   * @param tableName 表名
   * @param values 插入数据
   * @returns 插入数量
   */
  public static async batchInsert(rdbStore: ohosDataRdb.RdbStore, tableName: string,
                                  values: data_rdb.ValuesBucket[]): Promise<number> {
    try {
      return await rdbStore.batchInsert(tableName, values);
    } catch (err) {
      Log.error(TAG, `batchInsert tableName:${tableName} error: ${err?.code}, ${err?.message}`);
    }

    return 0;
  }

  /**
   * 插入
   *
   * @param rdbStore 数据库链接
   * @param tableName 表名
   * @param values 插入数据
   * @returns row ID
   */
  public static async insert(rdbStore: ohosDataRdb.RdbStore, tableName: string,
                             value: data_rdb.ValuesBucket): Promise<number> {
    try {
      return await rdbStore.insert(tableName, value);
    } catch (err) {
      Log.error(TAG, `insert tableName:${tableName} error: ${err?.code}, ${err?.message}`);
    }

    return 0;
  }

  /**
   * 更新
   *
   * @param rdbStore 数据库链接
   * @param tableName 表名
   * @param values 更新数据
   * @param predicates 条件
   * @returns 更新数量
   */
  public static async update(rdbStore: ohosDataRdb.RdbStore, tableName: string,
                             value: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates) {
    try {
      return await rdbStore.update(tableName, value, predicates);
    } catch (err) {
      Log.error(TAG, `update tableName:${tableName} error: ${err?.code}, ${err?.message}`);
    }

    return 0;
  }

  /**
   * 插入（回调方式）
   *
   * @param rdbStore 数据库链接
   * @param tableName 表名
   * @param values 插入数据
   * @param callback 回调函数
   */
  public static insertCallBack(rdbStore: ohosDataRdb.RdbStore, tableName: string,
                               value: data_rdb.ValuesBucket, callback: AsyncCallback<number, void>) {
    try {
      rdbStore.insert(tableName, value, (err, count) => {
        callback(err, count);
      });
    } catch (err) {
      Log.error(TAG, `insertCallBack tableName:${tableName} error: ${err?.code}, ${err?.message}`);
    }
  }

  /**
   * 更新（回调方式）
   *
   * @param rdbStore 数据库链接
   * @param tableName 表名
   * @param values 更新数据
   * @param predicates 条件
   * @param callback 回调函数
   */
  public static updateCallBack(rdbStore: ohosDataRdb.RdbStore, tableName: string,
                               value: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates,
                               callback: AsyncCallback<number, void>) {
    try {
      rdbStore.update(tableName, value, predicates, (err, count) => {
        callback(err, count);
      });
    } catch (err) {
      Log.error(TAG, `updateCallBack tableName:${tableName} error: ${err?.code}, ${err?.message}`);
    }
  }

  /**
   * 刪除（回调方式）
   *
   * @param rdbStore 数据库链接
   * @param tableName 表名
   * @param predicates 条件
   * @param callback 回调函数
   */
  public static deleteCallBack(rdbStore: ohosDataRdb.RdbStore, tableName: string,
                               predicates: dataSharePredicates.DataSharePredicates,
                               callback: AsyncCallback<number, void>) {
    try {
      rdbStore.delete(tableName, predicates, (err, count) => {
        callback(err, count);
      });
    } catch (err) {
      Log.error(TAG, `deleteCallBack tableName:${tableName} error: ${err?.code}, ${err?.message}`);
    }
  }
}