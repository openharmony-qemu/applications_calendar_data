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
import { Constants } from '@ohos/datastructure/src/main/ets/Constants';
import {
  CalendarsColumns,
  DEFAULT_CALENDAR_VALUE
} from '@ohos/datastructure/src/main/ets/calendars/CalendarsColumns';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { ValueType } from '@ohos.data.ValuesBucket';

/**
 * 初始化数据中的 creator。保护 creator 字段无法被应用自定义插入
 *
 * @param values 插入的数据
 * @param creator 调用接口的应用
 */
export function initValueCreator(values: data_rdb.ValuesBucket, creator: ValueType) {
  values[Constants.CREATOR] = creator;
}

/**
 * 低级别权限下无法操作其他应用的账户。接口的 predicates 中带上其他应用的信息会冲突，无法进行操作
 *
 * @param predicates
 * @param creator 调用接口的应用
 */
export function initPredicateCreator(predicates: dataSharePredicates.DataSharePredicates, creator: ValueType) {
  predicates.equalTo(Constants.CREATOR, creator);
}

/**
 * 低权限只能查找默认账户和自己应用下的账户。接口的 predicates 中带上应用的信息会冲突，无法进行操作
 *
 * @param predicates
 * @param creator 调用接口的应用
 */
export function initPredicateDefaultAndOwnCreator(predicates: dataSharePredicates.DataSharePredicates, creator: ValueType) {
  predicates.beginWrap()
    .equalTo(Constants.CREATOR, creator)
    .or()
    .beginWrap()
    .equalTo(CalendarsColumns.ACCOUNT_TYPE, DEFAULT_CALENDAR_VALUE.account_type)
    .and()
    .equalTo(CalendarsColumns.ACCOUNT_NAME, DEFAULT_CALENDAR_VALUE.account_name)
    .and()
    .equalTo(Constants.CREATOR, DEFAULT_CALENDAR_VALUE.creator)
    .endWrap()
    .endWrap();
}

/**
 * 删除数据中的 creator 字段。保护 creator 字段无法被修改
 *
 * @param values 更新的数据
 */
export function deleteValueCreator(values: data_rdb.ValuesBucket): data_rdb.ValuesBucket {
  let valuesResult: data_rdb.ValuesBucket = {};
  for (let key of Object.keys(values)) {
    if (key === Constants.CREATOR) {
      continue;
    }
    valuesResult[key] = values[key];
  }
  return valuesResult;
}

/**
 * 保护默认账户无法被修改和删除。接口的 predicates 中带上默认账户的信息会冲突，无法进行操作
 *
 * @param predicates
 */
export function initPredicateDefaultCalendarProtect(predicates: dataSharePredicates.DataSharePredicates) {
  predicates.beginWrap()
    .notEqualTo(CalendarsColumns.ACCOUNT_TYPE, DEFAULT_CALENDAR_VALUE.account_type)
    .and()
    .notEqualTo(CalendarsColumns.ACCOUNT_NAME, DEFAULT_CALENDAR_VALUE.account_name)
    .and()
    .notEqualTo(Constants.CREATOR, DEFAULT_CALENDAR_VALUE.creator)
    .endWrap();
}