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
import { CalendarAlertsIndexes } from './CalendarAlertsIndexes';

/**
 * parse all columns for table CalendarAlerts
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseCalendarAlerts(resultSet: data_rdb.ResultSet, indexes: CalendarAlertsIndexes): CalendarAlerts | undefined {
  if (resultSet === null || resultSet === undefined) {
    return undefined;
  }
  let calendarAlerts: CalendarAlerts = new CalendarAlerts();
  if (indexes.idIndex >= 0) {
    calendarAlerts.id = resultSet.getLong(indexes.idIndex);
  }
  if (indexes.eventIdIndex >= 0) {
    calendarAlerts.eventId = resultSet.getLong(indexes.eventIdIndex);
  }
  if (indexes.beginIndex >= 0) {
    calendarAlerts.begin = resultSet.getLong(indexes.beginIndex);
  }
  if (indexes.endIndex >= 0) {
    calendarAlerts.end = resultSet.getLong(indexes.endIndex);
  }
  if (indexes.alarmTimeIndex >= 0) {
    calendarAlerts.alarmTime = resultSet.getLong(indexes.alarmTimeIndex);
  }
  if (indexes.creationTimeIndex >= 0) {
    calendarAlerts.creationTime = resultSet.getLong(indexes.creationTimeIndex);
  }
  if (indexes.receivedTimeIndex >= 0) {
    calendarAlerts.receivedTime = resultSet.getLong(indexes.receivedTimeIndex);
  }
  if (indexes.notifyTimeIndex >= 0) {
    calendarAlerts.notifyTime = resultSet.getLong(indexes.notifyTimeIndex);
  }
  if (indexes.stateIndex >= 0) {
    calendarAlerts.state = resultSet.getLong(indexes.stateIndex);
  }
  if (indexes.minutesIndex >= 0) {
    calendarAlerts.minutes = resultSet.getLong(indexes.minutesIndex);
  }
  if (indexes.creatorIndex >= 0) {
    calendarAlerts.creator = resultSet.getString(indexes.creatorIndex);
  }
  return calendarAlerts;
}