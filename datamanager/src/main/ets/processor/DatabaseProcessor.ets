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

/**
 * the interface of Database Processor
 *
 * @since 2022-05-28
 */
export interface DatabaseProcessor {
  /**
   * 高权限插入接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 插入的数据
   * @param callback 回调方法
   */
  insertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function);

  /**
   * 高权限批量插入接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 插入的数据
   * @param callback 回调方法
   */
  batchInsertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string,
                             values: data_rdb.ValuesBucket[], callback: Function): void;

  /**
   * 低权限插入接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 插入的数据
   * @param callback 回调方法
   */
  insertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function);

  /**
   * 低权限批量插入接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 插入的数据
   * @param callback 回调方法
   */
  batchInsertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string,
                            values: data_rdb.ValuesBucket[], callback: Function): void;

  /**
   * 高权限删除接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param predicates 删除条件
   * @param callback 回调方法
   */
  deleteByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function);

  /**
   * 低权限删除接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param predicates 删除条件
   * @param callback 回调方法
   */
  deleteByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function);

  /**
   * 高权限更新接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 更新的数据
   * @param predicates 更新条件
   * @param callback 回调方法
   */
  updateByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function);

  /**
   * 低权限更新接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 更新的数据
   * @param predicates 更新条件
   * @param callback 回调方法
   */
  updateByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function);

  /**
   * 高权限查询接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param columns 查询的列名
   * @param predicates 查询条件
   * @param callback 回调方法
   */
  queryByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function);

  /**
   * 低权限查询接口
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param columns 查询的列名
   * @param predicates 查询条件
   * @param callback 回调方法
   */
  queryByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function);
}