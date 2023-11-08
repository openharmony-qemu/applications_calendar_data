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
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import { CalendarAlertsColumns } from './CalendarAlertsColumns';

interface CalendarAlertsType {
  idIndex: number;
  eventIdIndex: number;
  beginIndex: number;
  endIndex: number;
  alarmTimeIndex: number;
  creationTimeIndex: number;
  receivedTimeIndex: number;
  notifyTimeIndex: number;
  stateIndex: number;
  minutesIndex: number;
  creatorIndex: number;
}

/**
 * the columns indexes for table CalendarAlerts
 *
 * @since 2022-09-19
 */
export class CalendarAlertsIndexes implements CalendarAlertsType {
  idIndex = 0;
  eventIdIndex = 0;
  beginIndex = 0;
  endIndex = 0;
  alarmTimeIndex = 0;
  creationTimeIndex = 0;
  receivedTimeIndex = 0;
  notifyTimeIndex = 0;
  stateIndex = 0;
  minutesIndex = 0;
  creatorIndex = 0;
}

/**
 * parse all indexes for table CalendarAlerts
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseCalendarAlertsIndexes(resultSet: data_rdb.ResultSet): CalendarAlertsIndexes | undefined {
  if (resultSet === null || resultSet === undefined) {
    return undefined;
  }
  let indexes: CalendarAlertsIndexes = new CalendarAlertsIndexes();
  indexes.idIndex = resultSet.getColumnIndex(CalendarAlertsColumns.ID);
  indexes.eventIdIndex = resultSet.getColumnIndex(CalendarAlertsColumns.EVENT_ID);
  indexes.beginIndex = resultSet.getColumnIndex(CalendarAlertsColumns.BEGIN);
  indexes.endIndex = resultSet.getColumnIndex(CalendarAlertsColumns.END);
  indexes.alarmTimeIndex = resultSet.getColumnIndex(CalendarAlertsColumns.ALARM_TIME);
  indexes.creationTimeIndex = resultSet.getColumnIndex(CalendarAlertsColumns.CREATION_TIME);
  indexes.receivedTimeIndex = resultSet.getColumnIndex(CalendarAlertsColumns.RECEIVED_TIME);
  indexes.notifyTimeIndex = resultSet.getColumnIndex(CalendarAlertsColumns.NOTIFY_TIME);
  indexes.stateIndex = resultSet.getColumnIndex(CalendarAlertsColumns.STATE);
  indexes.minutesIndex = resultSet.getColumnIndex(CalendarAlertsColumns.MINUTES);
  indexes.creatorIndex = resultSet.getColumnIndex(CalendarAlertsColumns.CREATOR);
  return indexes;
}