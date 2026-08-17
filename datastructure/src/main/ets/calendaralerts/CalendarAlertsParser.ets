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
import { CalendarAlerts } from './CalendarAlerts';
import { CalendarAlertsColumns } from './CalendarAlertsColumns';

/**
 * parse all columns for table CalendarAlerts
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseCalendarAlerts(resultSet: data_rdb.ResultSet): CalendarAlerts | undefined {
  if (resultSet === null || resultSet === undefined) {
    return undefined;
  }
  let calendarAlerts: CalendarAlerts = new CalendarAlerts();
  calendarAlerts.id = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.ID));
  calendarAlerts.eventId = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.EVENT_ID));
  calendarAlerts.eventUuid = resultSet.getString(resultSet.getColumnIndex(CalendarAlertsColumns.EVENT_UUID));
  calendarAlerts.begin = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.BEGIN));
  calendarAlerts.end = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.END));
  calendarAlerts.alarmTime = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.ALARM_TIME));
  calendarAlerts.creationTime = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.CREATION_TIME));
  calendarAlerts.receivedTime = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.RECEIVED_TIME));
  calendarAlerts.notifyTime = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.NOTIFY_TIME));
  calendarAlerts.state = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.STATE));
  calendarAlerts.minutes = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.MINUTES));
  calendarAlerts.creator = resultSet.getString(resultSet.getColumnIndex(CalendarAlertsColumns.CREATOR));
  calendarAlerts.title = resultSet.getString(resultSet.getColumnIndex(CalendarAlertsColumns.TITLE));
  calendarAlerts.content = resultSet.getString(resultSet.getColumnIndex(CalendarAlertsColumns.CONTENT));
  calendarAlerts.wantAgent = resultSet.getString(resultSet.getColumnIndex(CalendarAlertsColumns.WANT_AGENT));
  calendarAlerts.buttons = resultSet.getString(resultSet.getColumnIndex(CalendarAlertsColumns.BUTTONS));
  calendarAlerts.slotType = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.SLOT_TYPE));
  calendarAlerts.keepHeadsUp = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.KEEP_HEADSUP));
  calendarAlerts.type = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.TYPE));
  calendarAlerts.identifier = resultSet.getString(resultSet.getColumnIndex(CalendarAlertsColumns.IDENTIFIER));
  calendarAlerts.needAgent = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.NEED_AGENT));
  calendarAlerts.snoozeTimes = resultSet.getLong(resultSet.getColumnIndex(CalendarAlertsColumns.SNOOZE_TIMES));
  calendarAlerts.uuid = resultSet.getString(resultSet.getColumnIndex(CalendarAlertsColumns.UUID));
  return calendarAlerts;
}