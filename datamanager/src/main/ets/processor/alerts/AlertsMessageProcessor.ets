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

import { dataShare } from '@kit.ArkData';
import data_rdb from '@ohos.data.relationalStore';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import {
  getCurrentTimeZoneMillisecond,
  MILLS_PER_DAY,
  MILLS_PER_HOUR,
  MILLS_PER_MINUTE,
  MILLS_PER_WEEK
} from '@ohos/common/src/main/ets/utils/TimeUtils';

import { CalendarAlerts } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlerts';
import { CalendarAlertStateType } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlertStateType';
import { ReminderMethodType } from '@ohos/datastructure/src/main/ets/reminders/ReminderMethodType';
import CalendarDataHelper from '../../utils/CalendarDataHelper';
import { acquireExpandAllAsync } from '../instances/InstancesProcessor';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import {
  CalendarAlertsColumns,
  CalendarsColumns,
  EventColumns,
  InstancesColumns,
  RemindersColumns
} from '@ohos/datastructure';
import { notifyCalendarAlertsChanged } from '../../commonevents/notify/ProviderChangeNotifier';
import { insertOrUpdateAlerts, parseAlerts } from './AlertsMessageHelper';
import { emitter } from '@kit.BasicServicesKit';
import { CommonInnerEvent, CustomTime } from '@ohos/common';
import { DefaultProcessor } from '../DefaultProcessor';

const TAG = 'AlertsMessageHandler';

const SCHEDULE_ALARM_SLACK = 12 * MILLS_PER_HOUR;

const CLEAR_OLD_ALARM_THRESHOLD = MILLS_PER_WEEK + SCHEDULE_ALARM_SLACK;

const ALLDAY_EVENT_ALARM_TIME = 9 * MILLS_PER_HOUR;

const INVALIDATE_TIME_MILLIS = -1;

const MILLS_ONE_MINUTE = 60 * 1000;

const ALL_DAY = 1;

const INVALID_CALENDAR_ALERTS_SELECTOR =
  `SELECT ca.${CalendarAlertsColumns.ID},ca.${CalendarAlertsColumns.ALARM_TIME},ca.${CalendarAlertsColumns.UUID} FROM ` +
  `${CalendarAlertsColumns.TABLE_NAME} AS ca LEFT OUTER JOIN ${InstancesColumns.TABLE_NAME} AS i ON ` +
  `(i.${InstancesColumns.EVENT_UUID}=ca.${CalendarAlertsColumns.EVENT_UUID} AND ` +
  `i.${InstancesColumns.BEGIN} / ${MILLS_ONE_MINUTE} = ` +
  `ca.${CalendarAlertsColumns.BEGIN} / ${MILLS_ONE_MINUTE}) LEFT OUTER JOIN ` +
  `${RemindersColumns.TABLE_NAME} AS r ON (ca.${CalendarAlertsColumns.EVENT_UUID}=r.${RemindersColumns.EVENT_UUID}` +
  ` AND ca.${CalendarAlertsColumns.MINUTES}=r.${RemindersColumns.MINUTES}) LEFT OUTER JOIN ` +
  `(${EventColumns.TABLE_NAME} AS e JOIN ${CalendarsColumns.TABLE_NAME} AS c ON (e.${EventColumns.CALENDAR_ID}=` +
  `c.${CalendarsColumns.ID})) ON (ca.${CalendarAlertsColumns.EVENT_UUID}=e.${EventColumns.UUID}) WHERE ` +
  `ca.${CalendarAlertsColumns.TYPE}=0 AND` +
  `(i.${InstancesColumns.BEGIN} ISNULL OR ca.${CalendarAlertsColumns.ALARM_TIME}<? OR ` +
  `(r.${RemindersColumns.MINUTES} ISNULL AND ca.${CalendarAlertsColumns.MINUTES}<>0) OR c.${CalendarsColumns.VISIBLE}=0)`;

const SINGLE_REMINDERS_SELECTOR = `select min ( ${RemindersColumns.ID} ) as _id FROM ${RemindersColumns.TABLE_NAME} ` +
  `group by ${RemindersColumns.EVENT_ID},${RemindersColumns.MINUTES},${RemindersColumns.METHOD}`;

const ALL_DAY_SUB_QUERY_PREFIX = `SELECT (${InstancesColumns.BEGIN} -? +
  (${ALLDAY_EVENT_ALARM_TIME}) - (${RemindersColumns.MINUTES}*${MILLS_PER_MINUTE}))`;

const SUB_QUERY_PREFIX = `SELECT ${InstancesColumns.BEGIN} -(${RemindersColumns.MINUTES}*${MILLS_PER_MINUTE})`;

const SUB_QUERY_SUFFIX = ` AS alertAlarmTime,${InstancesColumns.TABLE_NAME}.${InstancesColumns.EVENT_ID} AS eventId, ` +
  `${InstancesColumns.TABLE_NAME}.${InstancesColumns.EVENT_UUID} AS event_uuid, ` +
  `${EventColumns.TABLE_NAME}.${EventColumns.CREATOR} AS ${EventColumns.CREATOR}, ` +
  `${InstancesColumns.BEGIN},${InstancesColumns.END},${CalendarsColumns.TABLE_NAME}.account_type AS account_type,` +
  `${EventColumns.TITLE},${EventColumns.ALLDAY},${RemindersColumns.METHOD},${RemindersColumns.MINUTES} FROM ` +
  `${InstancesColumns.TABLE_NAME} INNER JOIN (${EventColumns.TABLE_NAME} JOIN ${CalendarsColumns.TABLE_NAME} ON ` +
  `(${EventColumns.TABLE_NAME}.${EventColumns.CALENDAR_UUID}=${CalendarsColumns.TABLE_NAME}.${CalendarsColumns.UUID}` +
  ` AND ${CalendarsColumns.TABLE_NAME}.${CalendarsColumns.CAN_REMINDER}=1)) ON ` +
  `(${EventColumns.TABLE_NAME}.${EventColumns.UUID}=${InstancesColumns.TABLE_NAME}.${InstancesColumns.EVENT_UUID}) ` +
  `INNER JOIN ${RemindersColumns.TABLE_NAME} ON (${InstancesColumns.TABLE_NAME}.${InstancesColumns.EVENT_UUID}=` +
  `${RemindersColumns.TABLE_NAME}.${RemindersColumns.EVENT_UUID}) WHERE ${CalendarsColumns.VISIBLE}=1 AND ` +
  `alertAlarmTime>=CAST(? AS INT) AND alertAlarmTime<=CAST(? AS INT) AND ` +
  `${InstancesColumns.END}>=? AND (${RemindersColumns.METHOD}=${ReminderMethodType.METHOD_ALERT} OR ` +
  `${RemindersColumns.METHOD}=${ReminderMethodType.METHOD_DEFAULT})`;

const ALL_DAY_QUERY = `${ALL_DAY_SUB_QUERY_PREFIX} ${SUB_QUERY_SUFFIX} AND ${EventColumns.ALLDAY}=1`;

const NO_ALL_DAY_QUERY = `${SUB_QUERY_PREFIX} ${SUB_QUERY_SUFFIX} AND ${EventColumns.ALLDAY}=0`;

const ALERT_GENERATE_QUERY =
  `SELECT * FROM (${ALL_DAY_QUERY} UNION ALL ${NO_ALL_DAY_QUERY}) ` +
    `ORDER BY alertAlarmTime,${InstancesColumns.BEGIN},${EventColumns.TITLE}`;

/**
 * 通知消息处理类
 *
 * @since 2024-12-15
 */
export class AlertsMessageProcessor extends DefaultProcessor{
  /**
   * 为下一个日历中的事件生成alarm
   *
   * @param isRemoveAlarms 是否需要移除状态为0的Alarms
   */
  public static async runScheduleNextAlarm(isRemoveAlarms: boolean = false) {
    Log.warn(TAG, 'runScheduleNextAlarm start.');
    let rdbStore = await CalendarDataHelper.getInstance().getRdbStore();
    if (!rdbStore) {
      Log.warn(TAG, 'runScheduleNextAlarm: rdbStore is null.');
      return;
    }
    await AlertsMessageProcessor.deleteRepeatReminders(rdbStore);
    try {
      if (isRemoveAlarms) {
        await AlertsMessageProcessor.removeScheduledAlarmsLocked(rdbStore);
      }
      const begin = Date.now();
      await AlertsMessageProcessor.scheduleNextAlarmLocked(rdbStore);
      Log.warn(TAG, `run schedule alarm cost: ${Date.now() - begin}`);
      emitter.emit({ eventId: CommonInnerEvent.REMIND_CALC_END });
    } catch (err) {
      emitter.emit({ eventId: CommonInnerEvent.REMIND_CALC_END });
      Log.error(TAG, `runScheduleNextAlarm error:${err}`);
    }
  }

  /**
   * 检索数据表，生成alarm
   *
   * @param rdbStore RdbStore
   */
  private static async scheduleNextAlarmLocked(rdbStore: data_rdb.RdbStore) {
    Log.info(TAG, 'scheduleNextAlarmLocked start.');
    let date = new Date(Date.now());
    date.setHours(date.getHours(), 0, 0, 0);
    let currentMillis = date.getTime();
    const start = currentMillis - SCHEDULE_ALARM_SLACK;
    const end = start + MILLS_PER_WEEK + MILLS_PER_HOUR + SCHEDULE_ALARM_SLACK;
    await AlertsMessageProcessor.deleteInvalidAlert(rdbStore, currentMillis);
    let nextAlarmTime = end;
    let tmpAlarmTime: number = await AlertsMessageProcessor.findNextAlarmTime(rdbStore);
    if (tmpAlarmTime !== INVALIDATE_TIME_MILLIS && tmpAlarmTime < nextAlarmTime) {
      nextAlarmTime = tmpAlarmTime + 3 * MILLS_PER_DAY;
    }
    const localOffset = getCurrentTimeZoneMillisecond(date);
    const queryParams = [localOffset.toString(), start.toString(), nextAlarmTime.toString(),
      currentMillis.toString(), start.toString(), nextAlarmTime.toString(), currentMillis.toString()];

    // 扩展Instances：扩展范围为前一天到后一天
    await acquireExpandAllAsync(start - MILLS_PER_DAY, end + MILLS_PER_DAY);
    await AlertsMessageProcessor.scheduleNextAlarmLockedSub(rdbStore, queryParams, nextAlarmTime, date);
    Log.info(TAG, 'scheduleNextAlarmLocked end.');
  }

  private static async scheduleNextAlarmLockedSub(rdbStore: data_rdb.RdbStore, queryParams: string[],
                                                  nextAlarmTime: number, date: Date) {
    let resultSet: data_rdb.ResultSet | null = null;
    try {
      resultSet = await rdbStore.querySql(ALERT_GENERATE_QUERY, queryParams);
      Log.warn(TAG, 'scheduleNextAlarmLocked() result row count is ' + resultSet.rowCount);
      const sqlAlerts: CalendarAlerts[] = [];
      while (resultSet.goToNextRow()) {
        let calendarAlerts: CalendarAlerts | undefined = parseAlerts(resultSet);
        if ((calendarAlerts === null) || (calendarAlerts === undefined)) {
          Log.warn(TAG, 'scheduleNextAlarmLocked() result is null or undefined');
          continue;
        }

        if (calendarAlerts.allDay === ALL_DAY) {
          calendarAlerts.end -= getCurrentTimeZoneMillisecond(date);
        }

        if (calendarAlerts.alarmTime < nextAlarmTime) {
          nextAlarmTime = calendarAlerts.alarmTime;
        }
        sqlAlerts.push(calendarAlerts);
      }
      await insertOrUpdateAlerts(rdbStore, sqlAlerts, date, new CustomTime(), false);
    } catch (err) {
      Log.error(TAG, `scheduleNextAlarmLockedSub error ${err?.message}, ${err?.code}`);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 查找给定时间之后的下一个alarm时间
   *
   * @param rdbStore RdbStore
   * @param mills 给定的事件
   * @return 返回下一个alarm的时间，如果不存在此类alarm，则返回-1
   */
  private static async findNextAlarmTime(rdbStore: data_rdb.RdbStore): Promise<number> {
    Log.info(TAG, 'findNextAlarmTime start.');
    let alarmTime = INVALIDATE_TIME_MILLIS;
    const columns = [CalendarAlertsColumns.ALARM_TIME];
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.greaterThanOrEqualTo(CalendarAlertsColumns.ALARM_TIME, new Date().getTime().toString());
    predicates.orderByAsc(CalendarAlertsColumns.ALARM_TIME);
    let resultSet: data_rdb.ResultSet | null = null;
    try {
      resultSet = await rdbStore.query(CalendarAlertsColumns.TABLE_NAME, predicates, columns);
      if ((resultSet === null) || (resultSet === undefined)) {
        return alarmTime;
      }
      if (resultSet.goToFirstRow()) {
        alarmTime = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.ALARM_TIME));
      }
    } catch (err) {
      Log.error(TAG, `findNextAlarmTime error ${err?.message}, ${err?.code}`);
    } finally {
      resultSet?.close();
    }
    return alarmTime;
  }

  /**
   * 移除状态为0的Alarms
   *
   * @param rdbStore
   */
  private static async removeScheduledAlarmsLocked(rdbStore: data_rdb.RdbStore) {
    Log.warn(TAG, 'removeScheduledAlarmsLocked start.');
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CalendarAlertsColumns.STATE, CalendarAlertStateType.STATE_SCHEDULED)
    try {
      await rdbStore.delete(CalendarAlertsColumns.TABLE_NAME, predicates);
      const valueBucket: ValuesBucket = {};
      valueBucket[CalendarAlertsColumns.ID] = 0;
      await notifyCalendarAlertsChanged(CalendarAlertsColumns.TABLE_NAME, dataShare.ChangeType.DELETE, [valueBucket]);
    } catch (err) {
      Log.error(TAG, `removeScheduledAlarmsLocked err: ${err?.code}, ${err?.message}`);
    }
  }

  /**
   * 删除无用的alarm
   *
   * @param rdbStore RdbStore
   * @param currentMillis 当前时间
   */
  private static async deleteInvalidAlert(rdbStore: data_rdb.RdbStore, currentMillis: number): Promise<void> {
    Log.warn(TAG, 'deleteInvalidAlert start.');
    let deleteUuidArray: string[] = [];
    const selectArg = [(currentMillis - CLEAR_OLD_ALARM_THRESHOLD).toString()];
    let resultSet: data_rdb.ResultSet | null = null;
    try {
      resultSet = await rdbStore.querySql(INVALID_CALENDAR_ALERTS_SELECTOR, selectArg);
      if ((resultSet === null) || (resultSet === undefined)) {
        Log.error(TAG, `deleteInvalidAlert Error.`);
        return;
      }
      if (!resultSet.goToFirstRow()) {
        Log.warn(TAG, `deleteInvalidAlert succeed 0.`);
        return;
      }
      const idColumnIndex = resultSet.getColumnIndex(CalendarAlertsColumns.ID);
      const uuidColumnIndex = resultSet.getColumnIndex(CalendarAlertsColumns.UUID);
      const alarmTimeColumnIndex = resultSet.getColumnIndex(CalendarAlertsColumns.ALARM_TIME);
      do {
        const deleteId = resultSet.getString(idColumnIndex);
        const deleteUuid = resultSet.getString(uuidColumnIndex);
        const deleteAlertTime = resultSet.getLong(alarmTimeColumnIndex);
        Log.warn(TAG, `delete invalid alert ${deleteId},alertTime:${deleteAlertTime}`);
        deleteUuidArray.push(deleteUuid);
      } while (resultSet.goToNextRow());
      const count = await AlertsMessageProcessor.batchDeleteByUuid(CalendarAlertsColumns.TABLE_NAME,
        deleteUuidArray, rdbStore);
      const valueBucket: ValuesBucket = {};
      valueBucket[CalendarAlertsColumns.ID] = 0;
      await notifyCalendarAlertsChanged(CalendarAlertsColumns.TABLE_NAME, dataShare.ChangeType.DELETE, [valueBucket]);
      Log.warn(TAG, `deleteInvalidAlert succeed ${count}`);
    } catch (err) {
      Log.error(TAG, `deleteInvalidAlert err: ${err?.code}, ${err?.message}`);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 删除重复的Reminder
   *
   * @param rdbStore RdbStore
   */
  private static async deleteRepeatReminders(rdbStore: data_rdb.RdbStore) {
    Log.warn(TAG, 'deleteRepeatReminders start.');
    let arraysList: number[] = [];
    let resultSet: data_rdb.ResultSet | null = null;
    try {
      resultSet = await rdbStore.querySql(
              `SELECT COUNT(*) FROM Reminders WHERE _id NOT IN (${SINGLE_REMINDERS_SELECTOR});`);
      if ((resultSet === null) || (resultSet === undefined)) {
        return;
      }
      if (!resultSet.goToFirstRow()) {
        Log.warn(TAG, `deleteRepeatReminders 0.`);
        return;
      }
      const count = resultSet.getLong(0);
      Log.warn(TAG, `deleteRepeatReminders ${count}.`);

      await rdbStore.executeSql(`DELETE FROM Reminders WHERE _id NOT IN (${SINGLE_REMINDERS_SELECTOR});`);
    } catch (err) {
      Log.error(TAG, `deleteRepeatReminders err: ${err?.code}, ${err?.message}`);
    } finally {
      resultSet?.close();
    }
  }

  private static async batchDeleteByUuid(table: string, uuidArray: string[], rdbStore: data_rdb.RdbStore,
                                   batchSize: number = 20): Promise<number> {
    let totalDeletedCount = 0;
    if (uuidArray.length <= 0) {
      return totalDeletedCount;
    }

    for (let i = 0; i < uuidArray.length; i += batchSize) {
      const batch = uuidArray.slice(i, i + batchSize);

      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.in(CalendarAlertsColumns.UUID, batch);

      const count = await rdbStore.delete(table, predicates);
      Log.warn(TAG, `deleteInvalidAlert succeed, count ${count}`);
      totalDeletedCount += count;
    }

    return totalDeletedCount;
  }

}