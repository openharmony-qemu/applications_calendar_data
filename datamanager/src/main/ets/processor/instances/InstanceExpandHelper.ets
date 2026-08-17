/**
 * @file Describe the file
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
import { EventColumns, EXPAND_COLUMNS } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { Events } from '@ohos/datastructure/src/main/ets/events/Events';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { HOURS_PER_DAY, MINUTES_PER_HOUR } from '@ohos/common/src/main/ets/utils/TimeUtils';
import { CustomTime, TIME_ZONE_UTC } from '@ohos/common/src/main/ets/time/CustTime';
import { Duration, lunarExpand, normalExpand, RecurrenceSet, recurringExpand } from '@ohos/rrule';
import { RdbStoreHelper } from '../../utils/RdbStoreHelper';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { EventIndexes, parseEventByIndex, parseIndexes } from '@ohos/datastructure';

const TAG = 'InstanceExpandHelper';

/**
 * 删除所有Instances
 * 如时区变化等场景，需要清空后重新扩展
 */
export async function deleteAllInstances(rdbStore: data_rdb.RdbStore): Promise<boolean> {
  const begin: number = Date.now();
  const predicate = new dataSharePredicates.DataSharePredicates();
  const count = await RdbStoreHelper.delete(rdbStore, InstancesColumns.TABLE_NAME, predicate);
  Log.warn(TAG, `deleteAllInstances ${count} cost ${Date.now() - begin}ms`);
  return true;
}

/**
 * 按时间范围扩展所有Instances
 *
 * @param beginTime 开始时间
 * @param end 结束时间
 */
export async function expandAllByRange(rdbStore: data_rdb.RdbStore, beginTime: number,
                                       endTime: number): Promise<boolean> {
  Log.info(TAG, `expandAllByRange called: ${beginTime}, ${endTime}`);
  const queryPredicates = getEventPredicateByBeginEnd(beginTime, endTime);
  let resultSet: data_rdb.ResultSet | null = null;
  try {
    resultSet = await rdbStore.query(queryPredicates, EXPAND_COLUMNS);
    Log.debug(TAG, `expandAllByRange query callback: ${resultSet}`);
    if ((resultSet !== null) && (resultSet !== undefined)) {
      if (resultSet.rowCount <= 0) {
        Log.info(TAG, `expandAllByRange ${beginTime}/${endTime} no event to be expand`);
        return true;
      }
      Log.warn(TAG, `prepare expand event size: ${resultSet.rowCount}, ${beginTime}/${endTime}`);
      return await expandInstancesByResultSet(rdbStore, resultSet, beginTime, endTime);
    }
  } catch (err) {
    Log.warn(TAG, `expandAllByRange err ${err?.message},${err?.code}`);
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  Log.warn(TAG, 'expandAllByRange end with empty cursor');
  return false;
}

/**
 * 按区间扩展Instances时，需要先查询需扩展的Events数据作为数据源，此方法提供查询的predicate
 * 1.对于非重复日程，只需要查询出开始时间或结束时间在所需区间内的日程，进行计算即可
 * 2.对于重复日程，只要开始时间小于所需区间end，就需要拿出来进行计算，因为这可能是一个无限循环的日程，没有截止时间
 *
 * @param beginTime 查询区间开始
 * @param endTime 查询区间结束
 * @returns 查询predicate
 */
function getEventPredicateByBeginEnd(beginTime: number, endTime: number): data_rdb.RdbPredicates {
  const predicates = new data_rdb.RdbPredicates(EventColumns.TABLE_NAME);

  // 1.非重复日程，rrule为空，dtstart和dtend任意在区间内即可
  predicates.beginWrap();
  predicates.beginWrap()
    .isNull(EventColumns.RRULE)
    .or()
    .equalTo(EventColumns.RRULE, '')
    .endWrap();
  // DTSTART小于等于endTime,保证日程不是扩展区间之后的日程
  // DTEND大于等于beginTime,保证日程不是扩展区间之前的日程
  predicates.and()
    .beginWrap()
    .lessThanOrEqualTo(EventColumns.DTSTART, endTime)
    .and()
    .greaterThanOrEqualTo(EventColumns.DTEND, beginTime)
    .endWrap();
  predicates.endWrap();

  // 2.重复日程，rrule非空，dtstart小于endTime即需要处理
  predicates.or().beginWrap();
  predicates.beginWrap()
    .isNotNull(EventColumns.RRULE)
    .and()
    .notEqualTo(EventColumns.RRULE, '')
    .endWrap();
  predicates.and().lessThanOrEqualTo(EventColumns.DTSTART, endTime);
  predicates.endWrap();

  return predicates;
}

/**
 * 扩展单个日程的Instances
 *
 * @param eventId 日程ID
 * @param beginTime 开始时间
 * @param endTime 结束时间
 */
export async function expandOneInRange(rdbStore: data_rdb.RdbStore, event: Events, expandedBegin: number,
                                       expandedEnd: number): Promise<boolean> {
  if ((event === null) || (event === undefined)) {
    Log.warn(TAG, 'expandOneInRange get invalid params');
    return false;
  }
  Log.info(TAG, `expandOneInRange id=${event.id}, range=${expandedBegin}/${expandedEnd}, eventTime=${event.dtStart}/${event.dtEnd}`);
  const instancesMap: InstancesMap = new InstancesMap();
  const customTime: CustomTime = new CustomTime();
  fillInstancesMapByEvent(instancesMap, event, customTime, expandedBegin, expandedEnd);
  if ((instancesMap !== null) && (instancesMap !== undefined)) {
    await batchInsertInstances(rdbStore, instancesMap);
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
async function expandInstancesByResultSet(rdbStore: data_rdb.RdbStore, resultSet: data_rdb.ResultSet,
                                          rangeBegin: number, rangeEnd: number): Promise<boolean> {
  Log.debug(TAG, 'expandInstancesByResultSet generateInstancesMap begin');
  const instancesMap = await generateInstancesMapFromValues(rdbStore, resultSet, rangeBegin, rangeEnd);
  Log.debug(TAG, `expandInstancesByResultSet generateInstancesMap end: ${instancesMap}`);
  if ((instancesMap !== null) && (instancesMap !== undefined)) {
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
async function generateInstancesMapFromValues(rdbStore: data_rdb.RdbStore, resultSet: data_rdb.ResultSet,
                                              rangeBegin: number, rangeEnd: number) {
  const moveToFirstSuccessful: boolean = resultSet.goToFirstRow();
  if (!moveToFirstSuccessful) {
    Log.error(TAG, 'generateInstancesMapFromValues move to first failed');
    return;
  }
  const instancesMap: InstancesMap = new InstancesMap();
  let event: Events | null | undefined;
  const customTime: CustomTime = new CustomTime();
  Log.info(TAG, `generateInstancesMap begin `);
  const indexes: EventIndexes | undefined = parseIndexes(resultSet);
  do {
    event = parseEventByIndex(resultSet, indexes);
    if ((event === null) || (event === undefined)) {
      continue;
    }
    fillInstancesMapByEvent(instancesMap, event, customTime, rangeBegin, rangeEnd);
  } while (resultSet.goToNextRow());
  Log.info(TAG, `instancesMap length: ${instancesMap.size}`);
  return instancesMap;
}

export function fillInstancesMapByEvent(instancesMap: InstancesMap, event: Events, customTime: CustomTime,
                                 rangeBegin: number, rangeEnd: number): void {
  const dates: number[] = getInstancesDatesByEvent(event, rangeBegin, rangeEnd);
  if (!dates || (dates.length == 0)) {
    Log.info(TAG, `no instances need generate for ${event.id} at ${rangeBegin}-${rangeEnd}`);
    return;
  }
  const durationMills: number = getDurationFromEvent(event);
  dates.forEach((begin: number) => {
    const contentValues: data_rdb.ValuesBucket = getContentValuesFromEvent(customTime,
      event, begin, durationMills);
    const syncIdKey = event.calendarId + '_' + event.id;
    instancesMap.pushInstances(syncIdKey, contentValues);
  });
}

function getDurationFromEvent(event: Events): number {
  let durationMills: number = Duration.defaultInstancesDuration();
  const duration: Duration = Duration.parse(event.duration);
  if (duration.isValid()) {
    durationMills = duration.getMills();
  } else if (event.dtEnd && (event.dtEnd > event.dtStart)) {
    durationMills = event.dtEnd - event.dtStart;
  }
  return durationMills;
}

/**
 * 根据日程数据，获取所有实例的begin时间的数组
 *
 * @param event
 * @returns 所有实例的begin时间数组，时区同event的时区
 */
function getInstancesDatesByEvent(event: Events, rangeBegin: number, rangeEnd: number): Array<number> {
  const dates: number[] = [];
  const begin: number = Date.now();
  const rruleSet: RecurrenceSet = new RecurrenceSet(event.rRule, event.rDate, event.exRule, event.exDate);
  try {
    if (event.isLunarEvent()) {
      lunarExpand(dates, event, rangeBegin, rangeEnd);
    } else if (rruleSet.hasRecurrence()) {
      recurringExpand(dates, event, rangeBegin, rangeEnd);
    } else {
      normalExpand(dates, event, rangeBegin, rangeEnd);
    }
  } catch (err) {
    Log.logErrorMsg(TAG, `expand event getErr: ${event.id}`, err);
  }
  Log.warn(TAG, `dates for ${event.id} : ${dates.length} cost ${Date.now() - begin}ms`);
  return dates;
}

/**
 * 根据Event数据生成Instances数据
 *
 * @param customTime 含时区和JulianDay计算能力的自定义Time类
 * @param event Event数据
 * @param instanceStart 实例开始时间，时间戳毫秒值
 * @param durationMills 实例持续时长，单位毫秒
 */
function getContentValuesFromEvent(customTime: CustomTime, event: Events, instanceStart: number,
                                   durationMills: number): data_rdb.ValuesBucket {
  customTime.setTimeZone(event.isAllDay() ? TIME_ZONE_UTC : event.eventTimeZone);
  customTime.setTime(instanceStart);
  const startDay: number = customTime.getJulianDay();
  const startMinute: number = customTime.getHourOfDay() * MINUTES_PER_HOUR + customTime.getMinute();

  const instanceEnd: number = instanceStart + durationMills;
  customTime.setTime(instanceEnd);
  let endDay: number = customTime.getJulianDay();
  let endMinute: number = customTime.getHourOfDay() * MINUTES_PER_HOUR + customTime.getMinute();

  // 午夜的特殊情况，当endMinute == 0.将前一天更改为+24小时
  // Exception: 如果startMinute和endMinute在同一天都为0,只留下endMinute.
  if (endMinute == 0 && (endDay > startDay)) {
    endMinute = HOURS_PER_DAY * MINUTES_PER_HOUR;
    endDay -= 1;
  }
  const uuid = `${event.uuid}${instanceStart}${instanceEnd}`;
  return {
    event_id: event.id,
    begin: instanceStart,
    end: instanceEnd,
    startDay: startDay,
    endDay: endDay,
    startMinute: startMinute,
    endMinute: endMinute,
    creator: event.creator,
    instanceUuid: uuid,
    event_uuid: event.uuid
  };
}

async function batchInsertInstances(rdbStore: data_rdb.RdbStore, instancesMap: InstancesMap): Promise<boolean> {
  Log.debug(TAG, `batchInsertInstances begin`);
  let item = Array.from(instancesMap.values());
  let instanceList: data_rdb.ValuesBucket[] = [];
  for (let valuesList of item) {
    instanceList.push(...valuesList);
  }

  if (instanceList.length === 0) {
    Log.info(TAG, `instanceList length is 0`);
    return true;
  }

  Log.warn(TAG, `InsertInstances begin: ${instanceList.length}`);
  let insertSuccess = false;
  // 批量插入Instances，插入失败后自动重试1次
  for (let index = 0; index <= 1; index++) {
    try {
      const count = await batchInsertWithTransaction(rdbStore, instanceList);
      if (count <= 0) {
        Log.warn(TAG, `${index} InsertInstances failed count= ${count}`);
        insertSuccess = false;
      } else {
        insertSuccess = true;
      }
    } catch (err) {
      // 当eventId、begin、end三个字段与表中已有数据一致时，产生表约束冲突会抛出异常，此报错可忽略
      // 为不影响其他Instances插入try-catch保护一下
      Log.error(TAG, `${index} InsertInstances get err:${err}`);
    }
    if (insertSuccess) {
      break;
    }
  }
  Log.warn(TAG, `InsertInstances end: ${insertSuccess}`);
  return insertSuccess;
}

/**
 * 事务性批量插入Instances表，要么全部插入成功，要么全部不插入
 * 插入大于1000时走事务，小于1000时不走事务
 *
 * @param rdbStore rdbStore对象
 * @param instanceList 待插入列表
 * @returns 插入成功的数量
 */
async function batchInsertWithTransaction(rdbStore: data_rdb.RdbStore, instanceList: data_rdb.ValuesBucket[]):
  Promise<number> {
  const batchCount = 1000;
  if (instanceList.length <= batchCount) {
    // 小于1000个，无需通过事务保障整体成功，无需分批处理，直接调用rdb接口批量插入
    return await rdbStore.batchInsert(InstancesColumns.TABLE_NAME, instanceList);
  }

  // 创建事务，commit或rollback后事务自动关闭，无需额外处理
  const transaction = await rdbStore.createTransaction();
  const totalLen = instanceList.length;
  let insertSuccessCount: number = 0;
  try {
    for (let index = 0; index < totalLen; index += batchCount) {
      const tmpList = instanceList.slice(index, index + batchCount);
      if (tmpList.length === 0) {
        continue;
      }
      const count = await transaction.batchInsert(InstancesColumns.TABLE_NAME, tmpList);
      Log.info(TAG, `batchInsert count=${count}/${insertSuccessCount}`);
      if (count <= 0) {
        // 插入失败，回滚事务
        await transaction.rollback();
        return 0;
      }
      insertSuccessCount += count;
    }
    // 全部插入成功，提交事务
    await transaction.commit();
  } catch (err) {
    Log.logErrorMsg(TAG, 'batchInsertWithTransaction', err);
    // 插入异常，回滚事务
    await transaction.rollback();
  }
  return insertSuccessCount;
}

/**
 * 存放Instances的集合Map
 *
 * @since 2022-05-28
 */
class InstancesMap extends Map<string, Array<data_rdb.ValuesBucket>> {
  /**
   * 以syncIdKey为key，将Instances对应的ValuesBucket放入集合Map中
   * 注：每个key对应一个Instances列表
   *
   * @param syncIdKey Map集合分类的key
   * @param values ValuesBucket数据，由此生成Instances实例
   */
  pushInstances(syncIdKey: string, values: data_rdb.ValuesBucket) {
    let instancesList: Array<data_rdb.ValuesBucket> | undefined = undefined;
    if (this.has(syncIdKey)) {
      instancesList = this.get(syncIdKey) as data_rdb.ValuesBucket[];
    }
    if (!instancesList || instancesList.length === 0) {
      instancesList = [];
      this.set(syncIdKey, instancesList);
    }
    instancesList.push(values);
  }
}