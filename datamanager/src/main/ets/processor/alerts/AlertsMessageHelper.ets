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

import { dataShare, relationalStore as rdb } from '@kit.ArkData';
import data_rdb from '@ohos.data.relationalStore';
import { Log } from '@ohos/common/src/main/ets/utils/Log';

import { CalendarAlerts } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlerts';
import { CalendarAlertStateType } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlertStateType';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { getReminderRequestCalendar } from '../reminders/ReminderAgentHelper';
import {
  CalendarAlertsColumns,
  CalendarsColumns,
  EventColumns,
  Events,
  NeedAgent,
  parseEvents
} from '@ohos/datastructure';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notifyCalendarAlertsChanged } from '../../commonevents/notify/ProviderChangeNotifier';
import { AlertsType } from '../../constants/AlertsTypeConstant';
import {
  CustomTime,
  GlobalThis,
  MILLS_PER_SECOND,
  SECONDS_PER_MINUTE,
} from '@ohos/common';
import { HashMap, HashSet } from '@kit.ArkTS';
import { parseCalendarAlerts } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlertsParser';

const TAG = 'AlertsMessageHandler';

export async function insertOrUpdateAlerts(rdbStore: data_rdb.RdbStore, alerts: CalendarAlerts[], date: Date,
                                           customTime: CustomTime, isSupportCustomRingUri: boolean) {
  Log.info(TAG, 'insertOrUpdateAlerts start');
  const eventUuidSet: HashSet<string> = new HashSet<string>();
  for (let index = 0; index < alerts.length; index++) {
    eventUuidSet.add(alerts[index].eventUuid);
  }
  const existAlerts: CalendarAlerts[] = await queryExistsCalendarAlerts(rdbStore, true);
  existAlerts.forEach((existAlert: CalendarAlerts) => {
    eventUuidSet.add(existAlert.eventUuid);
  });
  const eventUuidMap: HashMap<string, Events> = await queryEventByUuids(rdbStore, Array.from(eventUuidSet));
  const insertValues: ValuesBucket[] = [];
  const updateValues: ValuesBucket[] = [];
  const existingKeys = new Map<string, boolean>();
  for (let index = 0; index < alerts.length; index++) {
    const alertItem = alerts[index];
    const alertEvent = eventUuidMap.get(alertItem.eventUuid);
    const reminderRequest = await getReminderRequestCalendar(alertEvent, alertItem, customTime);
    if (!reminderRequest) {
      Log.warn(TAG, 'getReminderRequestCalendar fail');
      continue;
    }
    const valueBucket: ValuesBucket = generateValueBucket(alertItem, reminderRequest, date, isSupportCustomRingUri);
    const existAlarm: CalendarAlerts | undefined = getExistCalendarAlerts(alertItem, existAlerts);
    if (existAlarm) {
      // 判断是否更新
      const diffColumns = compareEvent(existAlarm, valueBucket);
      if (diffColumns.size === 0) {
        continue;
      }
      // 更新某个alert uuid不变
      valueBucket[CalendarAlertsColumns.UUID] = existAlarm.uuid;
      updateValues.push(valueBucket);
    } else {
      // 判断是否重复
      const needInsertExistAlarm = getInsertExistCalendarAlerts(alertItem, existAlerts);
      const oldEvent = needInsertExistAlarm ? eventUuidMap.get(needInsertExistAlarm.eventUuid) : undefined;
      const noNeedInsertResult = compareInsertEvent(oldEvent, alertEvent);
      if (noNeedInsertResult) {
        Log.warn(TAG, `this is a repeat alert. no need insert`);
        continue;
      }
      const key = `${valueBucket[CalendarAlertsColumns.BEGIN]},${valueBucket[CalendarAlertsColumns.END]},` +
        `${valueBucket[CalendarAlertsColumns.ALARM_TIME]},${valueBucket[CalendarAlertsColumns.TITLE]},` +
        `${valueBucket[CalendarAlertsColumns.SLOT_TYPE]}`;
      if (existingKeys.has(key)) {
        Log.warn(TAG, `duplicateInsert:${valueBucket[CalendarAlertsColumns.EVENT_ID]}-` +
          `${valueBucket[CalendarAlertsColumns.ALARM_TIME]}-(${valueBucket[CalendarAlertsColumns.BEGIN]},` +
          `${valueBucket[CalendarAlertsColumns.BEGIN]})`);
        continue;
      }
      // 若不满足上述情况，最后插入
      existingKeys.set(key, true);
      insertValues.push(valueBucket);
    }
  }
  await batchInsertAlerts(rdbStore, insertValues);
  await batchUpdateAlerts(rdbStore, updateValues, existAlerts);
  Log.info(TAG, `batchInsert count: ${insertValues.length}, batchUpdate count: ${updateValues.length}`);
}

export async function queryEventByUuids(rdbStore: data_rdb.RdbStore, uuids: string[]):
  Promise<HashMap<string, Events>> {
  const resultMap = new HashMap<string, Events>();
  if (!uuids || uuids.length === 0) {
    Log.warn(TAG, 'queryEventByUuids get invalid param');
    return resultMap;
  }
  const predicate = new data_rdb.RdbPredicates(EventColumns.TABLE_NAME);
  predicate.in(EventColumns.UUID, uuids);
  let resultSet: data_rdb.ResultSet | null = null;
  try {
    resultSet = await rdbStore.query(predicate);
    if (!resultSet) {
      Log.warn(TAG, 'queryEventByIds get invalid resultSet');
      return resultMap;
    }
    if (!resultSet.goToFirstRow()) {
      Log.warn(TAG, `queryEventByIds goToFirstRow fail ${resultSet.rowCount}`);
      return resultMap;
    }
    do {
      const event = parseEvents(resultSet);
      if (event) {
        resultMap.set(event.uuid, event);
      }
    } while (resultSet.goToNextRow());
  } catch (err) {
    Log.error(TAG, 'queryEventByIds');
  } finally {
    resultSet?.close();
  }
  return resultMap;
}

export async function queryExistsCalendarAlerts(rdbStore: data_rdb.RdbStore,
                                                log: boolean = false): Promise<CalendarAlerts[]> {
  const resultArr: CalendarAlerts[] = [];
  const predicate = new data_rdb.RdbPredicates(CalendarAlertsColumns.TABLE_NAME);
  let resultSet: data_rdb.ResultSet | null = null;
  try {
    resultSet = await rdbStore.query(predicate);
    if (!resultSet) {
      Log.warn(TAG, 'queryExistsCalendarAlerts get invalid resultSet');
      return resultArr;
    }
    if (!resultSet.goToFirstRow()) {
      Log.warn(TAG, `queryExistsCalendarAlerts goToFirstRow fail ${resultSet.rowCount}`);
      return resultArr;
    }
    do {
      const alert = parseCalendarAlerts(resultSet);
      if (alert) {
        resultArr.push(alert);
      }
      if (log && alert) {
        Log.warn(TAG, `ExistAlert：aId:${alert.id}-eId:${alert.eventId}-${alert.alarmTime}-(${alert.begin}, ` +
          `${alert.end})-${alert.creator}-${alert.creationTime}`);
      }
    } while (resultSet.goToNextRow());
  } catch (err) {
    Log.error(TAG, 'queryExistsCalendarAlerts');
  } finally {
    resultSet?.close();
  }
  Log.warn(TAG, `queryExistsCalendarAlerts ${resultArr.length}`);
  return resultArr;
}

async function queryAlertIdsByEventIds(rdbStore: data_rdb.RdbStore, eventIds: number[]): Promise<number[]> {
  const resultArr: number[] = [];
  if (!eventIds || eventIds.length === 0) {
    Log.warn(TAG, 'queryAlertIdsByEventIds get invalid param');
    return resultArr;
  }
  const predicate = new data_rdb.RdbPredicates(CalendarAlertsColumns.TABLE_NAME);
  predicate.in(CalendarAlertsColumns.EVENT_ID, eventIds);
  let resultSet: data_rdb.ResultSet | null = null;
  try {
    resultSet = await rdbStore.query(predicate, [CalendarAlertsColumns.ID, CalendarAlertsColumns.EVENT_ID]);
    if (!resultSet) {
      Log.warn(TAG, 'queryAlertIdsByEventIds get invalid resultSet');
      return resultArr;
    }
    if (!resultSet.goToFirstRow()) {
      Log.warn(TAG, `queryAlertIdsByEventIds goToFirstRow fail ${resultSet.rowCount}`);
      return resultArr;
    }
    do {
      const row = resultSet.getRow();
      const alertId = row[CalendarAlertsColumns.ID];
      const eventId = row[CalendarAlertsColumns.EVENT_ID];
      if (alertId) {
        resultArr.push(alertId as number);
        Log.warn(TAG, `insert alertId:${alertId}, eventId:${eventId}.`);
      }
    } while (resultSet.goToNextRow());
  } catch (err) {
    Log.error(TAG, 'queryAlertIdsByEventIds');
  } finally {
    resultSet?.close();
  }
  Log.warn(TAG, `queryAlertIdsByEventIds ${resultArr.length}, ${eventIds.length}`);
  return resultArr;
}

async function batchInsertAlerts(rdbStore: data_rdb.RdbStore, values: ValuesBucket[]) {
  if (values.length === 0) {
    Log.warn(TAG, 'no alerts to insert');
    return;
  }
  const eventIds: HashSet<number> = new HashSet();
  values.forEach((valueBucket: ValuesBucket) => {
    eventIds.add(valueBucket[CalendarAlertsColumns.EVENT_ID] as number);
  });
  try {
    const count = await rdbStore.batchInsert(CalendarAlertsColumns.TABLE_NAME, values);
    Log.warn(TAG, `batchInsert count: ${count}/${values.length}`);
  } catch (err) {
    Log.error(TAG, 'batchInsertAlerts');
  }
  const alertIds = await queryAlertIdsByEventIds(rdbStore, Array.from(eventIds));
  const notifyChangeValues: ValuesBucket[] = [];
  alertIds.forEach((alertId: number) => {
    const value = {} as ValuesBucket;
    value[CalendarAlertsColumns.ID] = alertId;
    notifyChangeValues.push(value);
  });
  await notifyCalendarAlertsChanged(CalendarAlertsColumns.TABLE_NAME, dataShare.ChangeType.INSERT, notifyChangeValues);
}

async function batchUpdateAlerts(rdbStore: data_rdb.RdbStore, values: ValuesBucket[], existAlerts: CalendarAlerts[]) {
  if (values.length === 0) {
    Log.warn(TAG, 'no alerts to update');
    return;
  }
  const eventIds: HashSet<number> = new HashSet();
  const insertValues: ValuesBucket[] = [];
  const updateValues: ValuesBucket[] = [];
  for (let index = 0; index < values.length; index++) {
    const valueBucket = values[index];
    try {
      const predicates: rdb.RdbPredicates = new rdb.RdbPredicates(CalendarAlertsColumns.TABLE_NAME);
      predicates.equalTo(CalendarAlertsColumns.EVENT_ID, valueBucket[CalendarAlertsColumns.EVENT_ID]);
      predicates.equalTo(CalendarAlertsColumns.BEGIN, valueBucket[CalendarAlertsColumns.BEGIN]);
      predicates.equalTo(CalendarAlertsColumns.MINUTES, valueBucket[CalendarAlertsColumns.MINUTES]);
      await rdbStore.update(valueBucket, predicates);
      eventIds.add(valueBucket[CalendarAlertsColumns.EVENT_ID] as number);
      Log.warn(TAG,
        `updateAlert:${valueBucket[CalendarAlertsColumns.EVENT_ID]}-${valueBucket[CalendarAlertsColumns.ALARM_TIME]}-` +
          `(${valueBucket[CalendarAlertsColumns.BEGIN]}, ${valueBucket[CalendarAlertsColumns.END]})`);
    } catch (err) {
      Log.error(TAG, `updateAlerts error ${err?.message}, ${err?.code}`);
    }
    const findAlert = existAlerts?.find((item: CalendarAlerts) => {
      return item.eventId === valueBucket[CalendarAlertsColumns.EVENT_ID] &&
        item.begin === valueBucket[CalendarAlertsColumns.BEGIN] &&
        item.minutes === valueBucket[CalendarAlertsColumns.MINUTES];
    });
    if (findAlert) {
      valueBucket[CalendarAlertsColumns.ID] = findAlert.id;
      if (findAlert.needAgent !== valueBucket[CalendarAlertsColumns.NEED_AGENT]) {
        insertValues.push(valueBucket);
      } else {
        updateValues.push(valueBucket);
      }
    }
  }
  // 提醒代理update场景notify需要完整的valueBucket, 如果needAgent变了需要走insert
  await notifyCalendarAlertsChanged(CalendarAlertsColumns.TABLE_NAME, dataShare.ChangeType.INSERT, insertValues);
  await notifyCalendarAlertsChanged(CalendarAlertsColumns.TABLE_NAME, dataShare.ChangeType.UPDATE, updateValues);
}

function generateValueBucket(calendarAlerts: CalendarAlerts, request: reminderAgentManager.ReminderRequestCalendar,
                             date: Date, isSupportCustomRing: boolean): ValuesBucket {
  let currentMillis = date.getTime();
  const valueBucket: ValuesBucket = preBuildValueBucket(calendarAlerts, request, isSupportCustomRing);
  fillAlertsValueBucket(valueBucket, calendarAlerts, currentMillis);
  return valueBucket;
}

export function compareEvent(calendarAlerts: CalendarAlerts, valueBucket: ValuesBucket): Set<CalendarAlertsColumns> {
  const diffColumns: Set<CalendarAlertsColumns> = new Set();
  if (valueBucket[CalendarAlertsColumns.TITLE] !== calendarAlerts.title) {
    Log.warn(TAG, 'update calendarAlerts by title.');
    diffColumns.add(CalendarAlertsColumns.TITLE);
  }
  // 全天、8:00-9:00
  if (valueBucket[CalendarAlertsColumns.CONTENT] !== calendarAlerts.content) {
    Log.warn(TAG, `update calendarAlerts by content.
      Before:${calendarAlerts.content}, Now:${valueBucket[CalendarAlertsColumns.CONTENT]}`);
    diffColumns.add(CalendarAlertsColumns.CONTENT);
  }
  // start、end变化
  if (valueBucket[CalendarAlertsColumns.WANT_AGENT] !== calendarAlerts.wantAgent) {
    Log.warn(TAG, `update calendarAlerts by wantAgent.
      Before:${calendarAlerts.begin}-${calendarAlerts.end}.
      Now:${valueBucket[CalendarAlertsColumns.BEGIN]}-${valueBucket[CalendarAlertsColumns.END]}`);
    diffColumns.add(CalendarAlertsColumns.WANT_AGENT);
  }
  if (valueBucket[CalendarAlertsColumns.BUTTONS] !== calendarAlerts.buttons) {
    Log.warn(TAG, 'update calendarAlerts by buttons. Language change.');
    diffColumns.add(CalendarAlertsColumns.BUTTONS);
  }
  if (valueBucket[CalendarAlertsColumns.SLOT_TYPE] !== calendarAlerts.slotType) {
    Log.warn(TAG, 'update calendarAlerts by slotType.');
    diffColumns.add(CalendarAlertsColumns.SLOT_TYPE);
  }
  if (valueBucket[CalendarAlertsColumns.KEEP_HEADSUP] !== calendarAlerts.keepHeadsUp) {
    Log.warn(TAG, 'update calendarAlerts by keepHeadsUp.');
    diffColumns.add(CalendarAlertsColumns.KEEP_HEADSUP);
  }
  // 是否走提醒代理发生变化
  if (valueBucket[CalendarAlertsColumns.NEED_AGENT] !== calendarAlerts.needAgent) {
    Log.warn(TAG, 'update calendarAlerts by needAgent.');
    diffColumns.add(CalendarAlertsColumns.NEED_AGENT);
  }
  return diffColumns;
}

function compareInsertEvent(oldEvent: Events | undefined, newEvent: Events | undefined): boolean {
  let result: boolean = false;
  if (oldEvent && newEvent) {
    result = (oldEvent.title === newEvent.title) && //标题
      (oldEvent.eventLocation === newEvent.eventLocation) && //地点
      (oldEvent.description === newEvent.description) && //描述
      (oldEvent.allDay === newEvent.allDay) && //全天
      (oldEvent.rRule === newEvent.rRule) && //重复规则
      (oldEvent.calendarId === newEvent.calendarId) && //账户
      (oldEvent.eventTimeZone === newEvent.eventTimeZone) && //时区
      (oldEvent.hwExtAlertType === newEvent.hwExtAlertType); //重要提醒
  }
  return result;
}

export function parseAlerts(resultSet: data_rdb.ResultSet): CalendarAlerts | undefined {
  if ((resultSet === null) || (resultSet === undefined)) {
    return undefined;
  }
  let calendarAlerts: CalendarAlerts = new CalendarAlerts();
  let dataResult: data_rdb.ValuesBucket = resultSet.getRow();
  calendarAlerts.id = dataResult[CalendarAlertsColumns.ID] as number ?? calendarAlerts.id;
  calendarAlerts.eventId = dataResult['eventId'] as number ?? calendarAlerts.eventId;
  calendarAlerts.eventUuid = dataResult[CalendarAlertsColumns.EVENT_UUID] as string ?? calendarAlerts.eventUuid;
  calendarAlerts.begin = dataResult[CalendarAlertsColumns.BEGIN] as number ?? calendarAlerts.begin;
  calendarAlerts.accountType = dataResult[CalendarAlertsColumns.ACCOUNT_TYPE] as string ?? calendarAlerts.accountType;
  calendarAlerts.end = dataResult[CalendarAlertsColumns.END] as number ?? calendarAlerts.end;
  calendarAlerts.alarmTime = dataResult['alertAlarmTime'] as number ?? calendarAlerts.alarmTime;
  calendarAlerts.creationTime =
    dataResult[CalendarAlertsColumns.CREATION_TIME] as number ?? calendarAlerts.creationTime;
  calendarAlerts.receivedTime =
    dataResult[CalendarAlertsColumns.RECEIVED_TIME] as number ?? calendarAlerts.receivedTime;
  calendarAlerts.notifyTime = dataResult[CalendarAlertsColumns.NOTIFY_TIME] as number ?? calendarAlerts.notifyTime;
  calendarAlerts.state = dataResult[CalendarAlertsColumns.STATE] as number ?? calendarAlerts.state;
  calendarAlerts.minutes = dataResult[CalendarAlertsColumns.MINUTES] as number ?? calendarAlerts.minutes;
  calendarAlerts.creator = dataResult[CalendarAlertsColumns.CREATOR] as string ?? calendarAlerts.creator;
  calendarAlerts.title = dataResult[CalendarAlertsColumns.TITLE] as string ?? calendarAlerts.title;
  calendarAlerts.content = dataResult[CalendarAlertsColumns.CONTENT] as string ?? calendarAlerts.content;
  calendarAlerts.wantAgent = dataResult[CalendarAlertsColumns.WANT_AGENT] as string ?? calendarAlerts.wantAgent;
  calendarAlerts.buttons = dataResult[CalendarAlertsColumns.BUTTONS] as string ?? calendarAlerts.buttons;
  calendarAlerts.slotType = dataResult[CalendarAlertsColumns.SLOT_TYPE] as number ?? calendarAlerts.slotType;
  calendarAlerts.keepHeadsUp = dataResult[CalendarAlertsColumns.KEEP_HEADSUP] as number ?? calendarAlerts.keepHeadsUp;
  calendarAlerts.allDay = dataResult[CalendarAlertsColumns.ALL_DAY] as number ?? calendarAlerts.allDay;
  calendarAlerts.needAgent = dataResult[CalendarAlertsColumns.NEED_AGENT] as number ?? calendarAlerts.needAgent;
  calendarAlerts.uuid = dataResult[CalendarsColumns.UUID] as string ?? calendarAlerts.uuid;
  return calendarAlerts;
}

/**
 * 查看alarm是否已经存在
 *
 * @param calendarAlerts 携带参数的calendarAlerts
 * @return 存在则返回true
 */
function getExistCalendarAlerts(calendarAlert: CalendarAlerts, existAlerts: CalendarAlerts[]):
CalendarAlerts | undefined {
  return existAlerts.find((existAlert: CalendarAlerts) => {
    return existAlert.eventUuid === calendarAlert.eventUuid && existAlert.begin === calendarAlert.begin &&
      existAlert.minutes === calendarAlert.minutes;
  });
}

function getInsertExistCalendarAlerts(calendarAlert: CalendarAlerts, existAlerts: CalendarAlerts[]):
CalendarAlerts | undefined {
  return existAlerts.find((existAlert: CalendarAlerts) => {
    return existAlert.begin === calendarAlert.begin && existAlert.end === calendarAlert.end &&
      existAlert.alarmTime === calendarAlert.alarmTime && existAlert.title === calendarAlert.title &&
      existAlert.slotType === calendarAlert.slotType;
  });
}

function fillAlertsValueBucket(valueBucket: ValuesBucket, calendarAlerts: CalendarAlerts, currentMillis: number) {
  valueBucket[CalendarAlertsColumns.MINUTES] = calendarAlerts.minutes;
  valueBucket[CalendarAlertsColumns.CREATOR] = calendarAlerts.creator;
  valueBucket[CalendarAlertsColumns.RECEIVED_TIME] = 0;
  valueBucket[CalendarAlertsColumns.NOTIFY_TIME] = 0;
  valueBucket[CalendarAlertsColumns.EVENT_ID] = calendarAlerts.eventId;
  valueBucket[CalendarAlertsColumns.EVENT_UUID] = calendarAlerts.eventUuid;
  calendarAlerts.begin = convertTimeInMinute(calendarAlerts.begin);
  valueBucket[CalendarAlertsColumns.BEGIN] = calendarAlerts.begin;
  calendarAlerts.end = convertTimeInMinute(calendarAlerts.end);
  valueBucket[CalendarAlertsColumns.END] = calendarAlerts.end;
  calendarAlerts.alarmTime = convertTimeInMinute(calendarAlerts.alarmTime);
  valueBucket[CalendarAlertsColumns.ALARM_TIME] = calendarAlerts.alarmTime;
  valueBucket[CalendarAlertsColumns.CREATION_TIME] = currentMillis;
  valueBucket[CalendarAlertsColumns.TYPE] = AlertsType.NORMAL;
  valueBucket[CalendarAlertsColumns.IDENTIFIER] =
    calendarAlerts.eventId.toString() + calendarAlerts.alarmTime;
  valueBucket[CalendarAlertsColumns.UUID] = calendarAlerts.uuid;
  valueBucket[CalendarAlertsColumns.NEED_AGENT] = NeedAgent.YES;
}

export function convertTimeInMinute(date: number): number {
  // 去掉时间戳里面的毫秒数和秒，保留到分级
  const dateSecond = Math.floor(date / MILLS_PER_SECOND);
  const dateMinute = dateSecond - dateSecond % SECONDS_PER_MINUTE;
  return dateMinute * MILLS_PER_SECOND;
}

function preBuildValueBucket(calendarAlerts: CalendarAlerts, request: reminderAgentManager.ReminderRequestCalendar,
                             isSupportCustomRing: boolean): ValuesBucket {
  const valueBucket: ValuesBucket = {};
  valueBucket[CalendarAlertsColumns.STATE] = CalendarAlertStateType.STATE_SCHEDULED;
  if (request.title) {
    valueBucket[CalendarAlertsColumns.TITLE] = request.title;
  } else {
    valueBucket[CalendarAlertsColumns.TITLE] = '';
  }
  if (request.content) {
    valueBucket[CalendarAlertsColumns.CONTENT] = request.content;
  } else {
    valueBucket[CalendarAlertsColumns.CONTENT] = '';
  }

  if (request.wantAgent) {
    valueBucket[CalendarAlertsColumns.WANT_AGENT] = JSON.stringify(request.wantAgent);
  } else {
    valueBucket[CalendarAlertsColumns.WANT_AGENT] = '';
  }

  if (request.actionButton) {
    valueBucket[CalendarAlertsColumns.BUTTONS] = JSON.stringify(request.actionButton);
  } else {
    valueBucket[CalendarAlertsColumns.BUTTONS] = '';
  }
  valueBucket[CalendarAlertsColumns.SLOT_TYPE] = calendarAlerts.slotType;
  valueBucket[CalendarAlertsColumns.KEEP_HEADSUP] = calendarAlerts.keepHeadsUp;
  // 自定义铃声字段完整，则写入字段
  if (isSupportCustomRing) {
    valueBucket[CalendarAlertsColumns.CUSTOM_RING_URI] = request.customRingUri ?? '';
    valueBucket[CalendarAlertsColumns.RING_DURATION] = request.ringDuration ?? 0;
    valueBucket[CalendarAlertsColumns.TIME_INTERVAL] = request.timeInterval ?? 0;
    valueBucket[CalendarAlertsColumns.SNOOZE_TIMES] = request.snoozeTimes ?? 0;
    valueBucket[CalendarAlertsColumns.SNOOZE_SLOT_TYPE] = request.snoozeSlotType ?? 0;
    valueBucket[CalendarAlertsColumns.SNOOZE_CONTENT] = request.snoozeContent ?? '';
    valueBucket[CalendarAlertsColumns.EXPIRED_CONTENT] = request.expiredContent ?? '';
    if (request.maxScreenWantAgent && typeof request.maxScreenWantAgent === 'object') {
      valueBucket[CalendarAlertsColumns.MAX_SCREEN_WANT_AGENT] = JSON.stringify(request.maxScreenWantAgent);
    } else {
      valueBucket[CalendarAlertsColumns.MAX_SCREEN_WANT_AGENT] = '';
    }
  }
  valueBucket[CalendarAlertsColumns.UUID] = calendarAlerts.uuid;
  return valueBucket;
}