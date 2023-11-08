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
import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns'
import { Events } from '@ohos/datastructure/src/main/ets/events/Events'
import { EventIndexes, parseIndexes } from '@ohos/datastructure/src/main/ets/events/EventIndexes'
import { parseEvents } from '@ohos/datastructure/src/main/ets/events/EventParser'
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns'
import { RecurrenceSet } from '@ohos/rrule/src/main/ets/RecurrenceSet'
import { Log } from '@ohos/common/src/main/ets/utils/Log'
import { getJulianDayByMills } from '@ohos/common/src/main/ets/time/JulianDay'
import { getMinutesByMills, HOURS_PER_DAY, MINUTES_PER_HOUR } from '@ohos/common/src/main/ets/utils/TimeUtils'

const TAG = "InstanceExpandHelper"

/**
 * 删除所有Instances
 * 如时区变化等场景，需要清空后重新扩展
 */
export async function deleteAllInstances(rdbStore: data_rdb.RdbStore): Promise<boolean> {
  const predicate = new data_rdb.RdbPredicates(InstancesColumns.TABLE_NAME);
  const result = await rdbStore.delete(predicate);
  return result >= 0;
}

/**
 * 按时间范围扩展所有Instances
 *
 * @param beginTime 开始时间
 * @param end 结束时间
 */
export async function expandAllByRange(rdbStore: data_rdb.RdbStore, beginTime: number, endTime: number): Promise<boolean> {
  Log.info(TAG, `expandAllByRange called: ${beginTime}, ${endTime}, rdbStore=${rdbStore}`);
  const queryPredicates = new data_rdb.RdbPredicates(EventColumns.TABLE_NAME);
  queryPredicates.between(EventColumns.DTSTART, beginTime, endTime);
  const columns = [EventColumns.ID, EventColumns.TITLE, EventColumns.DTSTART, EventColumns.DTEND, EventColumns.CREATOR];
  let resultSet: data_rdb.ResultSet | null = null;
  try {
    resultSet = await rdbStore.query(queryPredicates, columns);
    Log.debug(TAG, `expandAllByRange query callback: ${resultSet}`);
    if (resultSet !== null && resultSet !== undefined) {
      if (resultSet.rowCount <= 0) {
        Log.info(TAG, `expandAllByRange ${beginTime}/${endTime} no event to be expand`);
        return true;
      }
      return await expandInstancesByResultSet(rdbStore, resultSet);
    }
  } catch (err) {
    Log.warn(TAG, `expandAllByRange err ${JSON.stringify(err)}`);
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  Log.warn(TAG, "expandAllByRange end with empty cursor");
  return false
}

/**
 * 扩展单个日程的Instances
 *
 * @param eventId 日程ID
 * @param beginTime 开始时间
 * @param endTime 结束时间
 */
export function expandOneInRange(rdbStore: data_rdb.RdbStore, event: Events, expandedBegin: number, expandedEnd: number): boolean {
  if (event === null || event === undefined) {
    Log.warn(TAG, 'expandOneInRange get invalid params');
    return false;
  }
  Log.info(TAG, `expandOneInRange id=${event.id}, range=${expandedBegin}/${expandedEnd}`);
  const instancesMap: InstancesMap = new InstancesMap();
  const rruleSet: RecurrenceSet = new RecurrenceSet(event.rRule, event.rDate, event.exRule, event.exDate);
  const date = new Date();
  if (rruleSet.hasRecurrence()) {
    Log.warn(TAG, "generateInstancesMapFromValues not support rrule event yet");
  } else {
    if (event.dtStart > expandedEnd || event.dtEnd < expandedBegin) {
      Log.debug(TAG, `expandOneInRange not in expandedRange:${event.dtStart}/${event.dtEnd}`);
      return true;
    }
    const contentValues: data_rdb.ValuesBucket = getContentValuesFromEvent(date, event);
    const syncIdKey = event.calendarId + "_" + event.id;
    instancesMap.pushInstances(syncIdKey, contentValues);
  }
  if (instancesMap !== null && instancesMap !== undefined) {
    batchInsertInstances(rdbStore, instancesMap);
    return true;
  }
  return false;
}

/**
 * 扩展单个日程的Instances
 *
 * @param eventId 日程ID
 * @param beginTime 开始时间
 * @param endTime 结束时间
 */
export function expandAllByPredicates(rdbStore: data_rdb.RdbStore, eventId: number, expandedBegin: number, expandedEnd: number): boolean {
  return false;
}

/**
 * 根据数据库查询的ResultSet扩展生成Instances并插入数据库
 *
 * @param rdbStore 数据库实例
 * @param resultSet Events表查询到的结果
 * @return true 处理成功 false 处理失败
 */
async function expandInstancesByResultSet(rdbStore: data_rdb.RdbStore, resultSet: data_rdb.ResultSet): Promise<boolean> {
  Log.debug(TAG, 'expandInstancesByResultSet generateInstancesMap begin');
  const instancesMap = generateInstancesMapFromValues(resultSet);
  Log.debug(TAG, `expandInstancesByResultSet generateInstancesMap end: ${instancesMap}`);
  if (instancesMap !== null && instancesMap !== undefined) {
    return await batchInsertInstances(rdbStore, instancesMap);
  }
  Log.warn(TAG, 'expandInstancesByResultSet maybe occurs some error');
  return false;
}

/**
 * 根据日程信息，生成待插入的Instances列表数据
 * 如果是重复日程，则列表中含多个Instances数据
 * 如果不是重复日程，则列表中只含一个Instances数据
 *
 * @param resultSet db.query结果集
 */
function generateInstancesMapFromValues(resultSet: data_rdb.ResultSet) {
  const moveToFirstSuccessful: boolean = resultSet.goToFirstRow();
  if (!moveToFirstSuccessful) {
    Log.error(TAG, "generateInstancesMapFromValues move to first failed");
    return;
  }
  const instancesMap: InstancesMap = new InstancesMap();
  const indexes: EventIndexes = parseIndexes(resultSet) as EventIndexes;
  let event: Events | undefined = undefined;
  const date: Date = new Date();
  do {
    event = parseEvents(resultSet, indexes);
    if (event === null || event === undefined) {
      continue;
    }
    const rruleSet: RecurrenceSet = new RecurrenceSet(event.rRule, event.rDate, event.exRule, event.exDate);
    if (rruleSet.hasRecurrence()) {
      Log.warn(TAG, "generateInstancesMapFromValues not support rrule event yet");
    }
    const contentValues: data_rdb.ValuesBucket = getContentValuesFromEvent(date, event);
    const syncIdKey = event.calendarId + "_" + event.id;
    instancesMap.pushInstances(syncIdKey, contentValues);
  } while (resultSet.goToNextRow());
  return instancesMap;
}

/**
 * 根据Event数据生成Instances数据
 *
 * @param event Event数据
 */
function getContentValuesFromEvent(date: Date, event: Events): data_rdb.ValuesBucket {
  const startDay = getJulianDayByMills(date, event.dtStart);
  let endDay = getJulianDayByMills(date, event.dtEnd);
  const startMinute = getMinutesByMills(date, event.dtStart);
  let endMinute = getMinutesByMills(date, event.dtEnd);

  // 午夜的特殊情况，当endMinute == 0.将前一天更改为+24小时
  // Exception: 如果startMinute和endMinute在同一天都为0,只留下endMinute.
  if (endMinute == 0 && endDay > startDay) {
    endMinute = HOURS_PER_DAY * MINUTES_PER_HOUR;
    endDay -= 1;
  }
  return {
    event_id: event.id,
    begin: event.dtStart,
    end: event.dtEnd,
    startDay: startDay,
    endDay: endDay,
    startMinute: startMinute,
    endMinute: endMinute,
    creator: event.creator
  }
}

async function batchInsertInstances(rdbStore: data_rdb.RdbStore, instancesMap: InstancesMap): Promise<boolean> {
  Log.debug(TAG, `batchInsertInstances begin`);
  for (let i = 0; i < Object.values(instancesMap).length; i++) {
    let valuesList: Array<data_rdb.ValuesBucket> = Object.values(instancesMap)[i];
    for (let j = 0; j < valuesList.length; j++) {
      Log.debug(TAG, `InsertInstances begin: ${instancesValuesToString(valuesList[j])}`);
      try {
        const rowId = await rdbStore.insert(InstancesColumns.TABLE_NAME, valuesList[j]);
        if (rowId < 0) {
          Log.warn(TAG, `InsertInstances failed ${instancesValuesToString(valuesList[j])}`);
          return false;
        }
      } catch (err) {
        // 当eventId、begin、end三个字段与表中已有数据一致时，产生表约束冲突会抛出异常，此报错可忽略
        // 为不影响其他Instances插入try-catch保护一下
        Log.error(TAG, `InsertInstances get err:${err}`);
      }
      Log.debug(TAG, `InsertInstances end: ${instancesValuesToString(valuesList[i])}`);
    }
  }
  Log.debug(TAG, `batchInsertInstances successful`);
  return true;
}

function instancesValuesToString(values: data_rdb.ValuesBucket): string {
  return `eventId=${values.event_id},begin=${values.begin},end=${values.end}, startDay=${values.startDay}`
    + `,endDay=${values.endDay},startMinute=${values.startMinute},endMinute=${values.endMinute}`;
}

/**
 * 存放Instances的集合Map
 *
 * @since 2022-05-28
 */
class InstancesMap extends Map<string, Array<data_rdb.ValuesBucket>> {
  instancesList: Array<data_rdb.ValuesBucket> = [];
  /**
   * 以syncIdKey为key，将Instances对应的ValuesBucket放入集合Map中
   * 注：每个key对应一个Instances列表
   *
   * @param syncIdKey Map集合分类的key
   * @param values ValuesBucket数据，由此生成Instances实例
   */
  pushInstances(syncIdKey: string, values: data_rdb.ValuesBucket) {
    if (this.has(syncIdKey)) {
      this.instancesList = this.get(syncIdKey) as data_rdb.ValuesBucket[];
    }
    if (this.instancesList === null || this.instancesList === undefined || this.instancesList?.length === 0) {
      this.instancesList = new Array<data_rdb.ValuesBucket>();
      this.set(syncIdKey, this.instancesList);
    }
    this.instancesList.push(values);
  }
}