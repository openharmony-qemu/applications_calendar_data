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
import { sendBroadcast } from '@ohos/common/src/main/ets/broadcast/BroadcastHelper';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import {
  getCurrentTimeZoneMillisecond,
  MILLS_PER_MINUTE,
  MILLS_PER_HOUR,
  MILLS_PER_DAY,
  MILLS_PER_WEEK
} from '@ohos/common/src/main/ets/utils/TimeUtils';
import { getBundleNameByUri } from '@ohos/common/src/main/ets/utils/UrlUtils';

import { CalendarAccountType } from '@ohos/datastructure/src/main/ets/calendars/CalendarAccountType';
import { CalendarAlerts } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlerts';
import { parseCalendarAlerts } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlertsParser';
import { CalendarAlertState } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlertStateType';
import { CalendarAlertsColumns } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlertsColumns';
import { CalendarAlertsIndexes } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlertsIndexes';
import { CalendarsColumns } from '@ohos/datastructure/src/main/ets/calendars/CalendarsColumns';
import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { parseEvents } from '@ohos/datastructure/src/main/ets/events/EventParser';
import { Events } from '@ohos/datastructure/src/main/ets/events/Events';
import { EventIndexes, parseIndexes } from '@ohos/datastructure/src/main/ets/events/EventIndexes';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';
import { ReminderMethodType } from '@ohos/datastructure/src/main/ets/reminders/ReminderMethodType';
import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';

import { CommonEventConstants } from '../../commonevents/CommonEventConstants';
import { DefaultProcessor } from '../DefaultProcessor';
import { ErrorCode } from '../../constants/ErrorCode';
import { notifyEventReminder } from '../../commonevents/notify/ScheduleAlarmNotifier';
import CalendarDataHelper from '../../utils/CalendarDataHelper';
import { acquireExpandAll } from '../instances/InstancesProcessor';
import { initValueCreator, initPredicateCreator, deleteValueCreator } from '../DatabaseProcessorHelper';
import { ValueType, ValuesBucket } from '@ohos.data.ValuesBucket';
import { BusinessError } from '@ohos.base';

const TAG = 'AlertsProcessor';

const SCHEDULE_ALARM_SLACK = 2 * MILLS_PER_HOUR;

const CLEAR_OLD_ALARM_THRESHOLD = MILLS_PER_WEEK + SCHEDULE_ALARM_SLACK;

const ALLDAY_EVENT_ALARM_TIME = 9 * MILLS_PER_HOUR;

const INVALIDATE_TIME_MILLIS = -1;

const INVALID_CALENDARALERTS_SELECTOR = `SELECT ca.${CalendarAlertsColumns.ID} FROM `
+ `${CalendarAlertsColumns.TABLE_NAME} AS ca LEFT OUTER JOIN ${InstancesColumns.TABLE_NAME} USING `
+ `(${InstancesColumns.EVENT_ID},${InstancesColumns.BEGIN},${InstancesColumns.END}) LEFT OUTER JOIN `
+ `${RemindersColumns.TABLE_NAME} AS r ON (ca.${CalendarAlertsColumns.EVENT_ID}=r.${RemindersColumns.EVENT_ID} AND `
+ `ca.${CalendarAlertsColumns.MINUTES}=r.${RemindersColumns.MINUTES}) LEFT OUTER JOIN `
+ `(${EventColumns.TABLE_NAME} AS e JOIN ${CalendarsColumns.TABLE_NAME} AS c ON (e.${EventColumns.CALENDAR_ID}=`
+ `c.${CalendarsColumns.ID})) ON (ca.${CalendarAlertsColumns.EVENT_ID}=e.${EventColumns.ID}) WHERE `
+ `${InstancesColumns.TABLE_NAME}.${InstancesColumns.BEGIN} ISNULL OR ca.${CalendarAlertsColumns.ALARM_TIME}<? OR `
+ `(r.${RemindersColumns.MINUTES} ISNULL AND ca.${CalendarAlertsColumns.MINUTES}<>0) OR `
+ `c.${CalendarsColumns.CAN_REMINDER}=0 OR c.${CalendarsColumns.VISIBLE}=0`;

const SINGLE_REMINDERS_SELECTOR = `select min ( ${RemindersColumns.ID} ) as _id FROM ${RemindersColumns.TABLE_NAME} `
+ `group by ${RemindersColumns.EVENT_ID},${RemindersColumns.MINUTES},${RemindersColumns.METHOD}`;

const ALL_DAY_SUB_QUERY_PREFIX = `SELECT (CASE WHEN `
+ `${CalendarsColumns.ACCOUNT_TYPE}='${CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE}' THEN `
+ `${InstancesColumns.BEGIN} -? -(${RemindersColumns.MINUTES}*${MILLS_PER_MINUTE}) ELSE `
+ `${InstancesColumns.BEGIN} -? + (${ALLDAY_EVENT_ALARM_TIME}) -`
+ `(${RemindersColumns.MINUTES}*${MILLS_PER_MINUTE}) END)`;

const SUB_QUERY_PREFIX = `SELECT ${InstancesColumns.BEGIN} -(${RemindersColumns.MINUTES}*${MILLS_PER_MINUTE})`;

const SUB_QUERY_SUFFIX = ` AS alertAlarmTime,${InstancesColumns.TABLE_NAME}.${InstancesColumns.EVENT_ID} AS eventId, `
+ `${EventColumns.TABLE_NAME}.${EventColumns.CREATOR} AS ${EventColumns.CREATOR}, `
+ `${InstancesColumns.BEGIN},${InstancesColumns.END},${CalendarsColumns.TABLE_NAME}.account_type AS account_type,`
+ `${EventColumns.TITLE},${EventColumns.ALLDAY},${RemindersColumns.METHOD},${RemindersColumns.MINUTES} FROM `
+ `${InstancesColumns.TABLE_NAME} INNER JOIN (${EventColumns.TABLE_NAME} JOIN ${CalendarsColumns.TABLE_NAME} ON `
+ `(${EventColumns.TABLE_NAME}.${EventColumns.CALENDAR_ID}=${CalendarsColumns.TABLE_NAME}.${CalendarsColumns.ID})) ON `
+ `(${EventColumns.TABLE_NAME}.${EventColumns.ID}=${InstancesColumns.TABLE_NAME}.${InstancesColumns.EVENT_ID}) `
+ `INNER JOIN ${RemindersColumns.TABLE_NAME} ON (${InstancesColumns.TABLE_NAME}.${InstancesColumns.EVENT_ID}=`
+ `${RemindersColumns.TABLE_NAME}.${RemindersColumns.EVENT_ID}) WHERE ${CalendarsColumns.VISIBLE}=1 AND `
+ `${CalendarsColumns.CAN_REMINDER}=1 AND alertAlarmTime>=CAST(? AS INT) AND alertAlarmTime<=CAST(? AS INT) AND `
+ `${InstancesColumns.END}>=? AND ${RemindersColumns.METHOD}=${ReminderMethodType.METHOD_ALERT}`;

const ALL_DAY_QUERY = `${ALL_DAY_SUB_QUERY_PREFIX} ${SUB_QUERY_SUFFIX} AND ${EventColumns.ALLDAY}=1`;

const NO_ALL_DAY_QUERY = `${SUB_QUERY_PREFIX} ${SUB_QUERY_SUFFIX} AND ${EventColumns.ALLDAY}=0`;

const ALERT_GENERATE_QUERY = `SELECT * FROM (${ALL_DAY_QUERY} UNION ALL ${NO_ALL_DAY_QUERY}) WHERE 0=(SELECT count(*) FROM `
+ `${CalendarAlertsColumns.TABLE_NAME} CA WHERE CA.${CalendarAlertsColumns.EVENT_ID}=eventId AND `
+ `CA.${CalendarAlertsColumns.BEGIN}=${InstancesColumns.BEGIN} AND `
+ `CA.${CalendarAlertsColumns.ALARM_TIME}=alertAlarmTime) `
+ `ORDER BY alertAlarmTime,${InstancesColumns.BEGIN},${EventColumns.TITLE}`;

/**
 * the AlertsProcessor table processor
 *
 * @since 2022-10-25
 */
export class AlertsProcessor extends DefaultProcessor {
  async insertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    initValueCreator(values, callerName);
    const isEventExist = await isEventSameWithAlertId(rdbStore, values);
    if (isEventExist) {
      this.doInsert(rdbStore, uri, values, callback);
    } else {
      Log.warn(TAG, 'not support insert operation');
      const err: BusinessError = {
        code: ErrorCode.UN_SUPPORT_OPERATION,
        name: 'UnSupportedOperationException',
        message: 'The calling application cannot insert an reminder without its own event'
      };
      callback(err, -1);
    }
  }

  async insertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: ValuesBucket, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    initValueCreator(values, callerName);
    const isEventCreatorExist = await isEventSameWithAlertCreator(rdbStore, values);
    if (isEventCreatorExist) {
      this.doInsert(rdbStore, uri, values, callback);
    } else {
      Log.warn(TAG, 'not support insert operation');
      const err: BusinessError = {
        code: ErrorCode.UN_SUPPORT_OPERATION,
        name: 'UnSupportedOperationException',
        message: 'The calling application cannot insert an reminder with different creator from event'
      };
      callback(err, -1);
    }
  }

  async deleteByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    initPredicateCreator(predicates, callerName);
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  async updateByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    values = deleteValueCreator(values);
    this.doUpdate(rdbStore, uri, values, predicates, callback)
  }

  async updateByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    values = deleteValueCreator(values);
    initPredicateCreator(predicates, callerName);
    this.doUpdate(rdbStore, uri, values, predicates, callback)
  }

  async queryByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    initPredicateCreator(predicates, callerName);
    this.doQuery(rdbStore, uri, columns, predicates, callback);
  }
}

/**
 * 检查待插入的 alert 与 event 表中相同 event_id 的元组是否拥有相同的 creator
 *
 * @param rdbStore rdb数据库
 * @param values 插入操作的数据
 * @return true 相同 false 不相同
 */
async function isEventSameWithAlertCreator(rdbStore: data_rdb.RdbStore, values: ValuesBucket): Promise<boolean> {
  Log.debug(TAG, 'isEventSameWithAlertCreator start');
  const calendarAlertCreator = values[CalendarsColumns.CREATOR];
  let resultSet = await queryEventIdAndCreatorByAlert(rdbStore, values);
  if (resultSet === null || resultSet === undefined) {
    return false;
  }
  try {
    const eventIndexes: EventIndexes = parseIndexes(resultSet) as EventIndexes;
    if (resultSet.goToFirstRow()) {
      let events: Events | undefined = parseEvents(resultSet, eventIndexes);
      if (events === null || events === undefined) {
        return false;
      }
      return events.creator === calendarAlertCreator;
    }
  } catch (err) {
    Log.warn(TAG, `isEventSameWithAlertCreator err ${JSON.stringify(err)}`);
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  return false;
}

/**
 * 检查待插入的 alert 与 event 表中是否存在相同 event_id 的元组
 *
 * @param rdbStore rdb数据库
 * @param values 插入操作的数据
 * @return true 相同 false 不相同
 */
async function isEventSameWithAlertId(rdbStore: data_rdb.RdbStore, values: data_rdb.ValuesBucket): Promise<boolean> {
  Log.debug(TAG, 'isEventSameWithAlertId start');
  let resultSet = await queryEventIdAndCreatorByAlert(rdbStore, values);
  try {
    if (resultSet === null || resultSet === undefined) {
      return false;
    }
    if (resultSet.rowCount > 0) {
      return true;
    }
  } catch (err) {
    Log.warn(TAG, `isEventSameWithAlertId err ${JSON.stringify(err)}`);
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  return false;
}

/**
 * 查询待插入的 alert 数据中 event_id 与 event 表相同的结果
 *
 * @param rdbStore rdb数据库
 * @param values 插入操作的数据
 * @return DataShareResultSet
 */
async function queryEventIdAndCreatorByAlert(rdbStore: data_rdb.RdbStore, values: data_rdb.ValuesBucket) {
  const eventId = values[CalendarAlertsColumns.EVENT_ID] as ValueType;
  const columns = [EventColumns.ID, EventColumns.CREATOR];
  let predicates = new dataSharePredicates.DataSharePredicates();
  predicates.equalTo(EventColumns.ID, eventId);
  try {
    return await rdbStore.query(EventColumns.TABLE_NAME, predicates, columns);
  } catch (err) {
    Log.error(TAG, 'Event query data error');
  }
  return;
}

/**
 * 为下一个日历中的事件生成alarm
 *
 * @param isRemoveAlarms 是否需要移除状态为0的Alarms
 */
export async function runScheduleNextAlarm(isRemoveAlarms: boolean = false) {
  Log.info(TAG, 'runScheduleNextAlarm start.');
  let rdbStore = await CalendarDataHelper.getInstance().getRdbStore();
  if (!rdbStore) {
    Log.warn(TAG, 'runScheduleNextAlarm: rdbStore is null.');
    return;
  }
  await deleteRepeatReminders(rdbStore);
  try {
    if (isRemoveAlarms) {
      await removeScheduledAlarmsLocked(rdbStore);
    }
    await scheduleNextAlarmLocked(rdbStore);
  } catch (err) {
    Log.error(TAG, "runScheduleNextAlarm error");
  }
}

/**
 * 检索数据表，生成alarm，在提醒时间发送广播
 *
 * @param rdbStore RdbStore
 */
async function scheduleNextAlarmLocked(rdbStore: data_rdb.RdbStore) {
  Log.info(TAG, 'scheduleNextAlarmLocked start.');
  let rowsDeleted: number = 0;
  let isAlarmLessThenCurrent: boolean = false;
  const date: Date = new Date();
  let currentMillis = date.getTime();
  const start = currentMillis - SCHEDULE_ALARM_SLACK;
  const end = start + MILLS_PER_DAY + MILLS_PER_HOUR + SCHEDULE_ALARM_SLACK;

  try {
    rowsDeleted = await deleteInvalidAlert(rdbStore, currentMillis);
  } catch (err) {
    Log.error(TAG, 'TAG, Error in deleting invalidAlert');
  }

  let nextAlarmTime = end;
  try {
    let tmpAlarmTime: number = await findNextAlarmTime(rdbStore, currentMillis);
    if (tmpAlarmTime !== INVALIDATE_TIME_MILLIS && tmpAlarmTime < nextAlarmTime) {
      nextAlarmTime = tmpAlarmTime;
    }
  } catch (err) {
    Log.error(TAG, 'TAG, Error in getting nextAlarmTime');
  }
  const localOffset = getCurrentTimeZoneMillisecond(date);
  const queryParams = [localOffset.toString(), localOffset.toString(), start.toString(), nextAlarmTime.toString(),
  currentMillis.toString(), start.toString(), nextAlarmTime.toString(), currentMillis.toString()];

  // 扩展Instances：扩展范围为一天
  await acquireExpandAll(rdbStore, start - MILLS_PER_DAY, end + MILLS_PER_DAY);
  let resultSet: data_rdb.ResultSet | null = null;
  try {
    resultSet = await rdbStore.querySql(ALERT_GENERATE_QUERY, queryParams);
    Log.info(TAG, "scheduleNextAlarmLocked() result row count is " + resultSet.rowCount);
    const indexes: CalendarAlertsIndexes = parseScheduleCalendarAlertsIndexes(resultSet) as CalendarAlertsIndexes;
    while (resultSet.goToNextRow()) {
      let calendarAlerts: CalendarAlerts | undefined = parseCalendarAlerts(resultSet, indexes);
      if (calendarAlerts === null || calendarAlerts === undefined) {
        Log.debug(TAG, "scheduleNextAlarmLocked() result is null or undefined");
        continue;
      }
      if (calendarAlerts.alarmTime < nextAlarmTime) {
        nextAlarmTime = calendarAlerts.alarmTime;
      }

      const isExistAlarm = await alarmExists(rdbStore, calendarAlerts);
      if (isExistAlarm) {
        continue;
      }

      const rowId = await insertAlert(rdbStore, date, calendarAlerts);
      if (rowId == -1) {
        continue;
      }
      if (!await notifyEventReminder(calendarAlerts.alarmTime)) {
        isAlarmLessThenCurrent = true;
      }
    }
    if (isAlarmLessThenCurrent || rowsDeleted > 0) {
      sendBroadcast(CommonEventConstants.EVENT_REMINDER);
      runScheduleNextAlarm();
    }
  } catch (err) {
    Log.error(TAG, 'This is a resultSet ergodic error');
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
}

/**
 * 查找给定时间之后的下一个alarm时间
 *
 * @param rdbStore RdbStore
 * @param mills 给定的事件
 * @return 返回下一个alarm的时间，如果不存在此类alarm，则返回-1
 */
async function findNextAlarmTime(rdbStore: data_rdb.RdbStore, mills: number): Promise<number> {
  Log.info(TAG, 'findNextAlarmTime start.');
  let alarmTime = INVALIDATE_TIME_MILLIS;
  const columns = [CalendarAlertsColumns.ALARM_TIME];
  let predicates = new dataSharePredicates.DataSharePredicates();
  predicates.greaterThanOrEqualTo(CalendarAlertsColumns.ALARM_TIME, mills.toString());
  predicates.orderByAsc(CalendarAlertsColumns.ALARM_TIME);
  try {
    let resultSet = await rdbStore.query(CalendarAlertsColumns.TABLE_NAME, predicates, columns);
    if (resultSet === null || resultSet === undefined) {
      return alarmTime;
    }
    if (resultSet.goToFirstRow()) {
      alarmTime = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.ALARM_TIME));
      Log.debug(TAG, 'findNextAlarmTime succeed');
    }
  } catch (err) {
    Log.error(TAG, 'findNextAlarmTime error');
  }
  return alarmTime;
}

/**
 * 查看alarm是否已经存在
 *
 * @param calendarAlerts 携带参数的calendarAlerts
 * @return 存在则返回true
 */
async function alarmExists(rdbStore: data_rdb.RdbStore, calendarAlerts: CalendarAlerts): Promise<boolean> {
  let isExistAlarm = false;
  const columns = [CalendarAlertsColumns.ALARM_TIME];
  let predicates = new dataSharePredicates.DataSharePredicates();
  predicates.equalTo(InstancesColumns.EVENT_ID, calendarAlerts.eventId.toString());
  predicates.equalTo(CalendarAlertsColumns.BEGIN, calendarAlerts.begin.toString());
  predicates.equalTo(CalendarAlertsColumns.ALARM_TIME, calendarAlerts.alarmTime.toString());
  try {
    let resultSet = await rdbStore.query(CalendarAlertsColumns.TABLE_NAME, predicates, columns);
    if (resultSet === null || resultSet === undefined) {
      return isExistAlarm;
    }
    if (resultSet.rowCount > 0) {
      isExistAlarm = true;
      Log.debug(TAG, 'alarmExists:alarm already exist');
    }
  } catch (err) {
    Log.error(TAG, 'alarmExists query data error');
  }
  return isExistAlarm;
}

/**
 * 获取触发提醒sql语句所查询的Alert表的列
 *
 * @param resultSet 执行查询sql语句的结果
 * @return CalendarAlertsIndexes 返回查询的列Index
 */
function parseScheduleCalendarAlertsIndexes(resultSet: data_rdb.ResultSet) {
  if (resultSet === null || resultSet === undefined) {
    return;
  }
  let indexes: CalendarAlertsIndexes = new CalendarAlertsIndexes();
  indexes.alarmTimeIndex = resultSet.getColumnIndex('alertAlarmTime');
  indexes.eventIdIndex = resultSet.getColumnIndex('eventId');
  indexes.minutesIndex = resultSet.getColumnIndex(CalendarAlertsColumns.MINUTES);
  indexes.beginIndex = resultSet.getColumnIndex(CalendarAlertsColumns.BEGIN);
  indexes.endIndex = resultSet.getColumnIndex(CalendarAlertsColumns.END);
  indexes.creatorIndex = resultSet.getColumnIndex(CalendarAlertsColumns.CREATOR);
  return indexes;
}

/**
 * Alert插入数据表中
 *
 * @param calendarAlerts 携带参数的calendarAlerts
 * @return 成功则返回rowId
 */
async function insertAlert(rdbStore: data_rdb.RdbStore, date: Date, calendarAlerts: CalendarAlerts): Promise<number> {
  let currentMillis = date.getTime();
  let rowId: number = -1;
  const valueBucket: ValuesBucket = {};
  valueBucket[CalendarAlertsColumns.EVENT_ID] = calendarAlerts.eventId;
  valueBucket[CalendarAlertsColumns.BEGIN] = calendarAlerts.begin;
  valueBucket[CalendarAlertsColumns.END] = calendarAlerts.end;
  valueBucket[CalendarAlertsColumns.ALARM_TIME] = calendarAlerts.alarmTime;
  valueBucket[CalendarAlertsColumns.CREATION_TIME] = currentMillis;
  valueBucket[CalendarAlertsColumns.RECEIVED_TIME] = 0;
  valueBucket[CalendarAlertsColumns.NOTIFY_TIME] = 0;
  valueBucket[CalendarAlertsColumns.STATE] = CalendarAlertState.STATE_SCHEDULED;
  valueBucket[CalendarAlertsColumns.MINUTES] = calendarAlerts.minutes;
  valueBucket[CalendarAlertsColumns.CREATOR] = calendarAlerts.creator;
  try {
    rowId = await rdbStore.insert(CalendarAlertsColumns.TABLE_NAME, valueBucket);
    Log.debug(TAG, `insertAlert succeed , rowId = ${rowId}`);
  } catch (err) {
    Log.error(TAG, 'insertAlert error');
  }
  return rowId;
}

/**
 * 删除无用的alarm
 *
 * @param rdbStore RdbStore
 * @param currentMillis 当前时间
 * @return 成功则返回受影响的行数
 */
async function deleteInvalidAlert(rdbStore: data_rdb.RdbStore, currentMillis: number): Promise<number> {
  Log.info(TAG, 'deleteInvalidAlert start.');
  let rowsDeleted: number = 0;
  let arraysDeleteId: number[] = [];
  let predicates = new dataSharePredicates.DataSharePredicates();
  const selectArg = [(currentMillis - CLEAR_OLD_ALARM_THRESHOLD).toString()];
  try {
    let resultSet = await rdbStore.querySql(INVALID_CALENDARALERTS_SELECTOR, selectArg);
    if (resultSet === null || resultSet === undefined) {
      return 0;
    }
    if (!resultSet.goToFirstRow()) {
      return 0;
    }
    do {
      let deleteId = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.ID));
      arraysDeleteId.push(deleteId);
    } while (resultSet.goToNextRow());
    predicates.in(CalendarAlertsColumns.ID, arraysDeleteId);
    rowsDeleted = await rdbStore.delete(CalendarAlertsColumns.TABLE_NAME, predicates);
    Log.debug(TAG, `deleteInvalidAlert succeed, rowsDeleted = ${rowsDeleted}`);
  } catch (err) {
    Log.error(TAG, 'deleteInvalidAlert error');
  }
  return rowsDeleted;
}

/**
 * 删除重复的Reminder
 *
 * @param rdbStore RdbStore
 */
async function deleteRepeatReminders(rdbStore: data_rdb.RdbStore) {
  Log.info(TAG, 'deleteRepeatReminders start.');
  let arraysList: number[] = [];
  let predicates = new dataSharePredicates.DataSharePredicates();
  try {
    let resultSet = await rdbStore.querySql(SINGLE_REMINDERS_SELECTOR);
    if (resultSet === null || resultSet === undefined) {
      return;
    }
    if (!resultSet.goToFirstRow()) {
      return;
    }
    do {
      let deleteId = resultSet.getLong(resultSet.getColumnIndex(RemindersColumns.ID));
      arraysList.push(deleteId);
    } while (resultSet.goToNextRow());
    predicates.notIn(RemindersColumns.ID, arraysList);
    await rdbStore.delete(RemindersColumns.TABLE_NAME, predicates);
    Log.debug(TAG, `deleteRepeatReminders succeed`);
  } catch (err) {
    Log.error(TAG, 'deleteRepeatReminders error');
  }
}

/**
 * 移除状态为0的Alarms
 *
 * @param rdbStore
 */
async function removeScheduledAlarmsLocked(rdbStore: data_rdb.RdbStore) {
  Log.info(TAG, 'removeScheduledAlarmsLocked start.');
  let predicates = new dataSharePredicates.DataSharePredicates();
  predicates.equalTo(CalendarAlertsColumns.STATE, CalendarAlertState.STATE_SCHEDULED)
  try {
    await rdbStore.delete(CalendarAlertsColumns.TABLE_NAME, predicates);
    Log.debug(TAG, `removeScheduledAlarmsLocked succeed`);
  } catch (err) {
    Log.error(TAG, 'removeScheduledAlarmsLocked error');
  }
}

