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

import { Log } from "@ohos/common/src/main/ets/utils/Log";
import { isEmptyStr } from '@ohos/common/src/main/ets/utils/TextUtils';
import { isContainsOneOfKeys } from '@ohos/common/src/main/ets/utils/ValuesUtils';
import { getBundleNameByUri } from '@ohos/common/src/main/ets/utils/UrlUtils';

import { EventColumns, UPDATE_INSTANCES_COLUMNS } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { Events } from '@ohos/datastructure/src/main/ets/events/Events';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';

import { notifyProviderChange, OPERATION_UNKNOWN, } from '../../commonevents/notify/ProviderChangeNotifier';
import { DefaultProcessor } from "./../DefaultProcessor";
import { ErrorCode } from '../../constants/ErrorCode';
import { deleteAllInstances, expandAllByRange, expandOneInRange } from './InstanceExpandHelper';
import { generateInstancesQuerySql } from './InstancesQuerySqlGenerator';
import { isInExpandedRange, updateExpandedRange, getExpandedBegin, getExpandedEnd } from "./ExpandRangeManager";
import { InstancesQueryParams, parseParamsFromUri, isValidQueryParams } from './InstanceQueryParams';
import { BusinessError } from '@ohos.base';

const TAG = "InstancesProcessor";

/**
 * the instances table processor
 *
 * @since 2022-05-28
 */
export class InstancesProcessor extends DefaultProcessor {
  initParas() {
    this.logTag = TAG;
  }

  async insertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    Log.warn(this.logTag, 'not support insert operation');
    const err: BusinessError = {
      code: ErrorCode.UN_SUPPORT_OPERATION,
      name: 'UnSupportedOperationException',
      message: 'Instances Table not support insert operation'
    };
    callback(err, 0);
  }

  async insertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    this.insertByHighAuthority(rdbStore, uri, values, callback);
  }

  async deleteByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    Log.warn(this.logTag, 'not support delete operation');
    const err: BusinessError = {
      code: ErrorCode.UN_SUPPORT_OPERATION,
      name: 'UnSupportedOperationException',
      message: 'Instances Table not support delete operation'
    };
    callback(err, 0);
  }

  async deleteByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    this.deleteByHighAuthority(rdbStore, uri, predicates, callback);
  }

  async updateByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    Log.warn(this.logTag, 'not support update operation');
    const err: BusinessError = {
      code: ErrorCode.UN_SUPPORT_OPERATION,
      name: 'UnSupportedOperationException',
      message: 'Instances Table not support update operation'
    };
    callback(err, 0);
  }

  async updateByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    this.updateByHighAuthority(rdbStore, uri, values, predicates, callback);
  }

  async queryByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = '';
    this.queryByInstanceUri(rdbStore, uri, columns, callerName, callback);
  }

  async queryByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    this.queryByInstanceUri(rdbStore, uri, columns, callerName, callback);
  }

  /**
   * 解析 uri，根据 uri 进行 Instance 的联表查询
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri,包含查询参数
   * @param columns 查询的列名
   * @param callerName 调用方app的bundle_name
   * @param callback 回调方法
   */
  async queryByInstanceUri(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, callerName: string, callback: Function) {
    const params: InstancesQueryParams = parseParamsFromUri(uri) as InstancesQueryParams;
    if (!isValidQueryParams(params)) {
      const err: BusinessError = {
        code: ErrorCode.ILLEGAL_ARGUMENT_ERROR,
        name: 'IllegalArgumentError',
        message: 'query Instances must has begin&end or searchText params like ?begin=${begin}&end=${end}' +
          '&searchText=${searchText}'
      };
      callback(err, null);
      return;
    }
    if (params.isValidBeginEnd()) {
      await acquireExpandAll(rdbStore, params.getBegin(), params.getEnd());
    }
    doInstancesQuery(rdbStore, columns, params, callerName, callback);
  }
}

/**
 * 请求扩展Instances
 * 1.在已扩展范围内，则不扩展
 * 2.不在已扩展范围内，则按未扩展部分扩展全部
 *
 * @param begin 请求扩展的开始时间
 * @param end 请求扩展的结束时间
 */
export async function acquireExpandAll(rdbStore: data_rdb.RdbStore, acquireBegin: number, acquireEnd: number) {
  Log.info(TAG, `acquireExpandAll begin from ${acquireBegin} to ${acquireEnd}`);
  const isInRange = await isInExpandedRange(acquireBegin, acquireEnd);
  if (isInRange) {
    Log.info(TAG, `acquireExpandAll no need to expand`);
    return;
  }
  let expandedBegin = await getExpandedBegin();
  let expandedEnd = await getExpandedEnd();
  Log.info(TAG, `acquireExpandAll expanded range:${expandedBegin}/${expandedEnd}`);

  let shouldSendBroadcast: boolean = false;
  if (expandedEnd === 0) {
    Log.info(TAG, "acquireExpandAll first expand");
    await deleteAllInstances(rdbStore);
    let isSuccess = await expandAllByRange(rdbStore, acquireBegin, acquireEnd);
    if (isSuccess) {
      Log.info(TAG, `expandAllByRange successful from ${acquireBegin} to ${acquireEnd}`);
      updateExpandedRange(acquireBegin, acquireEnd);
      expandedBegin = acquireBegin;
      expandedEnd = acquireEnd;
      shouldSendBroadcast = true;
    }
  }

  // 处理比已扩展时间早的部分
  if (acquireBegin < expandedBegin) {
    let isSuccess = await expandAllByRange(rdbStore, acquireBegin, expandedBegin);
    if (isSuccess) {
      Log.info(TAG, `expandAllByRange successful from ${acquireBegin} to ${expandedBegin}`);
      updateExpandedRange(acquireBegin, expandedEnd);
      expandedBegin = acquireBegin;
      shouldSendBroadcast = true;
    }
  }

  // 处理比已扩展时间晚的部分
  if (acquireEnd > expandedEnd) {
    let isSuccess = await expandAllByRange(rdbStore, expandedEnd, acquireEnd);
    if (isSuccess) {
      Log.info(TAG, `expandAllByRange successful from ${expandedEnd} to ${acquireEnd}`);
      updateExpandedRange(expandedBegin, acquireEnd);
      expandedEnd = acquireEnd;
      shouldSendBroadcast = true;
    }
  }
  Log.info(TAG, `acquireExpandAll end from ${acquireBegin} to ${acquireEnd}`);

  if (shouldSendBroadcast) {
    notifyProviderChange(InstancesColumns.TABLE_NAME, OPERATION_UNKNOWN);
  }
}

/**
 * 请求扩展单个日程，用于日程创建/更新时
 *
 * @param eventId 日程ID
 * @param values ValuesBucket数据（创建时）或Events数据（更新时）
 */
export async function acquireExpandOne(rdbStore: data_rdb.RdbStore, rowId: number, values: data_rdb.ValuesBucket | Events | undefined) {
  const isSuccess = await expandOne(rdbStore, rowId, values);
  if (isSuccess) {
    notifyProviderChange(InstancesColumns.TABLE_NAME, OPERATION_UNKNOWN);
  } else {
    Log.warn(TAG, "expandOneByRange failed");
  }
}

/**
 * 扩展单个日程，用于日程创建/更新时
 *
 * @param eventId 日程ID
 * @param values ValuesBucket数据（创建时）或Events数据（更新时）
 */
export async function expandOne(rdbStore: data_rdb.RdbStore, rowId: number, values: data_rdb.ValuesBucket | Events | undefined): Promise<boolean> {
  if (values === null || values === undefined) {
    Log.error(TAG, 'acquireExpandOne get invalid params');
    return false;
  }
  const expandedBegin = await getExpandedBegin();
  const expandedEnd = await getExpandedEnd();
  let event: Events;
  if (values instanceof Events) {
    event = values;
  } else {
    event = new Events();
    event.id = rowId;
    parseEventsFromValues(values, event);
  }

  // 对于单个日程，仅对已全局扩展的时间范围内处理
  const isSuccess = expandOneInRange(rdbStore, event, expandedBegin, expandedEnd);
  return isSuccess;
}

/**
 * 请求刷新一条Event的Instances
 *
 * @param rdbStore rdb数据库
 * @param eventId 日程ID
 * @param event 日程数据信息
 */
export async function acquireUpdateOne(rdbStore: data_rdb.RdbStore, eventId: number, event: Events | undefined) {
  const predicate = new dataSharePredicates.DataSharePredicates();
  predicate.equalTo(InstancesColumns.EVENT_ID, eventId);
  await rdbStore.delete(InstancesColumns.TABLE_NAME, predicate);
  acquireExpandOne(rdbStore, eventId, event);
}

/**
 * 是否需要刷新Instances表，根据values内是否包含dtstart、rrule等关键字段来判断是否需要刷新Instances
 *
 * @param values 变更的values，以此判断是否需要刷新
 * @return true 需要刷新; false 不需要刷新
 */
export function isNeedRefreshInstances(values: data_rdb.ValuesBucket): boolean {
  if (values === null || values === undefined) {
    return false;
  }
  return isContainsOneOfKeys(values, UPDATE_INSTANCES_COLUMNS);
}

function parseEventsFromValues(values: data_rdb.ValuesBucket, event: Events): void {
  event.dtStart = values[EventColumns.DTSTART] as number;
  event.dtEnd = values[EventColumns.DTEND] as number;
  event.rRule = values[EventColumns.RRULE] as string;
  event.rDate = values[EventColumns.RDATE] as string;
  event.exRule = values[EventColumns.EXRULE] as string;
  event.exDate = values[EventColumns.EXDATE] as string;
  event.allDay = values[EventColumns.ALLDAY] as number;
  event.eventTimeZone = values[EventColumns.EVENT_TIMEZONE] as string;
  event.originalId = values[EventColumns.ORIGINAL_ID] as number;
  event.syncId = values[EventColumns.SYNC_ID] as string;
  event.originalSyncId = values[EventColumns.ORIGINAL_SYNC_ID] as string;
  event.lastDate = values[EventColumns.LAST_DATE] as number;
  event.originalInstanceTime = values[EventColumns.ORIGINAL_INSTANCE_TIME] as number;
  event.creator = values[EventColumns.CREATOR] as string;
}

function doInstancesQuery(rdbStore: data_rdb.RdbStore, columns: Array<string>, params: InstancesQueryParams, callerName: string, callback: Function): void {
  const sql = generateInstancesQuerySql(columns, params, callerName);
  if (!sql || isEmptyStr(sql)) {
    Log.error(TAG, `generate empty sql, the params maybe invalid`);
    return;
  }
  Log.info(TAG, `instances query sql=${sql}`);
  try {
    let instancesQueryFun = (err: BusinessError, resultSet: data_rdb.ResultSet) => {
      callback(err, resultSet);
    }
    rdbStore.querySql(sql, [], instancesQueryFun);
  } catch (err) {
    Log.error(TAG, `doInstancesQuery querySql get err:${err?.message}, SQL:${sql}`);
  }
}