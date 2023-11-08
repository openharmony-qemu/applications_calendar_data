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
import CalendarDataHelper from '../../utils/CalendarDataHelper';
import { CalendarMetaDataColumns } from '@ohos/datastructure/src/main/ets/calendarmetadata/CalendarMetaDataColumns'
import { Log } from '@ohos/common/src/main/ets/utils/Log'

const TAG = 'ExpandRangeManager'

// CalendarMetaData表唯一的数据ID，只允许存在一条记录
const UNIQUE_ID = 1

/**
 * CalendarMetaData表对应数据的缓存类
 *
 * @since 2022-05-28
 */
class CalendarMetaData {
  timeZone: string = '';

  expandedBegin: number = 0;

  expandedEnd: number = 0;

  isOnceRead: boolean = false;

  private static instance: CalendarMetaData;

  public static getInstance(): CalendarMetaData {
    if (!CalendarMetaData.instance) {
      CalendarMetaData.instance = new CalendarMetaData();
    }
    return CalendarMetaData.instance;
  }
}

/**
 * 是否在已扩展时间范围内
 *
 * @param begin 开始时间
 * @param end 结束时间
 */
export async function isInExpandedRange(begin: number, end: number): Promise<boolean> {
  const expandedBegin = await getExpandedBegin();
  const expandedEnd = await getExpandedEnd();
  return begin >= expandedBegin && end <= expandedEnd;
}

/**
 * 更新已扩展范围
 *
 * @param begin 开始时间，比原先开始时间小才更新
 * @param end 结束时间，比原先结束时间大才更新
 */
export function updateExpandedRange(begin: number, end: number) {
  const metaData = CalendarMetaData.getInstance();
  if (begin >= metaData.expandedBegin && end <= metaData.expandedEnd) {
    Log.info(TAG, "no need to updateExpandedRange");
    return;
  }
  if (begin < metaData.expandedBegin || metaData.expandedBegin === 0) {
    metaData.expandedBegin = begin;
  }
  if (end > metaData.expandedEnd || metaData.expandedEnd === 0) {
    metaData.expandedEnd = end;
  }

  CalendarDataHelper.getInstance().getRdbStore().then((rdb) => {
    if (!rdb) {
      Log.error(TAG, 'updateExpandedRange get some err');
      return;
    }
    const contentValues: data_rdb.ValuesBucket = {
      "minInstance": metaData.expandedBegin,
      "maxInstance": metaData.expandedEnd
    }
    try {
      rdb.update(contentValues, getPredicates());
    } catch (err) {
      Log.error(TAG, 'updateExpandedRange get some err');
    }
  })
}

/**
 * 重置已扩展时间范围
 */
export function resetExpandedRange() {
  const manager = CalendarMetaData.getInstance();
  manager.isOnceRead = false;
  manager.expandedBegin = 0;
  manager.expandedEnd = 0;
  updateExpandedRange(0, 0);
}

/**
 * 获取已扩展的开始时间
 */
export async function getExpandedBegin(): Promise<number> {
  const metaData = CalendarMetaData.getInstance();
  if (metaData.isOnceRead) {
    return metaData.expandedBegin;
  }
  await readFromDb();
  return metaData.expandedBegin;
}

/**
 * 获取已扩展的结束时间
 */
export async function getExpandedEnd(): Promise<number> {
  const metaData = CalendarMetaData.getInstance();
  if (metaData.isOnceRead) {
    return metaData.expandedEnd;
  }
  await readFromDb();
  return metaData.expandedEnd;
}

async function readFromDb() {
  Log.debug(TAG, "readFromDb begin");
  const rdb = await CalendarDataHelper.getInstance().getRdbStore();
  if (!rdb) {
    Log.warn(TAG, "readFromDb: the rdb is null");
    return;
  }
  const columns = [CalendarMetaDataColumns.MIN_INSTANCE, CalendarMetaDataColumns.MAX_INSTANCE, CalendarMetaDataColumns.LOCAL_TIME_ZONE];
  let resultSet: data_rdb.ResultSet = {} as data_rdb.ResultSet;
  try {
    resultSet = await rdb.query(getPredicates(), columns);
  } catch (err) {
    Log.error(TAG, 'readFromDb get some err');
  }
  try {
    Log.debug(TAG, `readFromDb resultSet:${resultSet}`);
    if (resultSet !== null && resultSet != undefined && resultSet.goToFirstRow()) {
      const metaData = CalendarMetaData.getInstance();
      metaData.timeZone = resultSet.getString(resultSet.getColumnIndex(CalendarMetaDataColumns.LOCAL_TIME_ZONE));
      metaData.expandedBegin = resultSet.getLong(resultSet.getColumnIndex(CalendarMetaDataColumns.MIN_INSTANCE));
      metaData.expandedEnd = resultSet.getLong(resultSet.getColumnIndex(CalendarMetaDataColumns.MAX_INSTANCE));
      metaData.isOnceRead = true;
      Log.debug(TAG, "readFromDb parse data successful");
    } else {
      await initMetaDataValue(rdb);
    }
  } catch (err) {
    Log.warn(TAG, `readFromDb err ${JSON.stringify(err)}`);
  }
  if (resultSet) {
    resultSet.close();
  }
  Log.debug(TAG, "readFromDb end");
}

async function initMetaDataValue(rdb: data_rdb.RdbStore) {
  Log.info(TAG, "initMetaDataValue begin");
  const metaData = CalendarMetaData.getInstance();
  metaData.timeZone = '';
  metaData.expandedBegin = 0;
  metaData.expandedEnd = 0;
  const contentValues: data_rdb.ValuesBucket = {
    "_id": UNIQUE_ID,
    "localTimeZone": '',
    "minInstance": metaData.expandedBegin,
    "maxInstance": metaData.expandedEnd
  }
  try {
    const rowId = await rdb.insert(CalendarMetaDataColumns.TABLE_NAME, contentValues);
    if (rowId < 0) {
      Log.warn(TAG, "initMetaDataValue failed");
    } else {
      metaData.isOnceRead = true;
      Log.info(TAG, "initMetaDataValue end");
    }
  } catch (err) {
    Log.error(TAG, 'initMetaDataValue get some err');
  }
}

function getPredicates(): data_rdb.RdbPredicates {
  return new data_rdb.RdbPredicates(CalendarMetaDataColumns.TABLE_NAME).equalTo(CalendarMetaDataColumns.ID, UNIQUE_ID);
}