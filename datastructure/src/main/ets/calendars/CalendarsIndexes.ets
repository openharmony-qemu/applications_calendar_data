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
import { CalendarsColumns } from './CalendarsColumns';

interface CalendarIndexesType {
  idIndex: number;
  accountNameIndex: number;
  accountTypeIndex: number;
  syncIdIndex: number;
  dirtyIndex: number;
  mutatorsIndex: number;
  nameIndex: number;
  calendarDisplayNameIndex: number;
  calendarColorIndex: number;
  calendarColorIndexIndex: number;
  calendarAccessLevelIndex: number;
  visibleIndex: number;
  syncEventsIndex: number;
  calendarLocationIndex: number;
  calendarTimezoneIndex: number;
  ownerAccountIndex: number;
  isPrimaryIndex: number;
  canOrganizerRespondIndex: number;
  canModifyTimeZoneIndex: number;
  canPartiallyUpdateIndex: number;
  maxRemindersIndex: number;
  allowedRemindersIndex: number;
  allowedAvailabilityIndex: number;
  allowedAttendeeTypesIndex: number;
  deletedIndex: number;
  calendarTimeStampIndex: number;
  calSync1Index: number;
  calSync2Index: number;
  calSync3Index: number;
  calSync4Index: number;
  calSync5Index: number;
  calSync6Index: number;
  calSync7Index: number;
  calSync8Index: number;
  calSync9Index: number;
  calSync10Index: number;
  canReminderIndex: number;
  creatorIndex: number;
}

/**
 * the columns indexes for table Calendars
 *
 * @since 2022-10-18
 */
export class CalendarsIndexes implements CalendarIndexesType {
  idIndex = 0;
  accountNameIndex = 0;
  accountTypeIndex = 0;
  syncIdIndex = 0;
  dirtyIndex = 0;
  mutatorsIndex = 0;
  nameIndex = 0;
  calendarDisplayNameIndex = 0;
  calendarColorIndex = 0;
  calendarColorIndexIndex = 0;
  calendarAccessLevelIndex = 0;
  visibleIndex = 0;
  syncEventsIndex = 0;
  calendarLocationIndex = 0;
  calendarTimezoneIndex = 0;
  ownerAccountIndex = 0;
  isPrimaryIndex = 0;
  canOrganizerRespondIndex = 0;
  canModifyTimeZoneIndex = 0;
  canPartiallyUpdateIndex = 0;
  maxRemindersIndex = 0;
  allowedRemindersIndex = 0;
  allowedAvailabilityIndex = 0;
  allowedAttendeeTypesIndex = 0;
  deletedIndex = 0;
  calendarTimeStampIndex = 0;
  calSync1Index = 0;
  calSync2Index = 0;
  calSync3Index = 0;
  calSync4Index = 0;
  calSync5Index = 0;
  calSync6Index = 0;
  calSync7Index = 0;
  calSync8Index = 0;
  calSync9Index = 0;
  calSync10Index = 0;
  canReminderIndex = 0;
  creatorIndex = 0;
}

/**
 * parse all indexes for table Calendars
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseCalendarsIndexes(resultSet: data_rdb.ResultSet): CalendarsIndexes | undefined {
  if (resultSet === null || resultSet === undefined) {
    return undefined;
  }
  let indexes: CalendarsIndexes = new CalendarsIndexes();
  indexes.idIndex = resultSet.getColumnIndex(CalendarsColumns.ID);
  indexes.accountNameIndex = resultSet.getColumnIndex(CalendarsColumns.ACCOUNT_NAME);
  indexes.accountTypeIndex = resultSet.getColumnIndex(CalendarsColumns.ACCOUNT_TYPE);
  indexes.syncIdIndex = resultSet.getColumnIndex(CalendarsColumns.SYNC_ID);
  indexes.dirtyIndex = resultSet.getColumnIndex(CalendarsColumns.DIRTY);
  indexes.mutatorsIndex = resultSet.getColumnIndex(CalendarsColumns.MUTATORS);
  indexes.nameIndex = resultSet.getColumnIndex(CalendarsColumns.NAME);
  indexes.calendarDisplayNameIndex = resultSet.getColumnIndex(CalendarsColumns.CALENDAR_DISPLAY_NAME);
  indexes.calendarColorIndex = resultSet.getColumnIndex(CalendarsColumns.CALENDAR_COLOR);
  indexes.calendarColorIndexIndex = resultSet.getColumnIndex(CalendarsColumns.CALENDAR_COLOR_INDEX);
  indexes.calendarAccessLevelIndex = resultSet.getColumnIndex(CalendarsColumns.CALENDAR_ACCESS_LEVEL);
  indexes.visibleIndex = resultSet.getColumnIndex(CalendarsColumns.VISIBLE);
  indexes.syncEventsIndex = resultSet.getColumnIndex(CalendarsColumns.SYNC_EVENTS);
  indexes.calendarLocationIndex = resultSet.getColumnIndex(CalendarsColumns.CALENDAR_LOCATION);
  indexes.calendarTimezoneIndex = resultSet.getColumnIndex(CalendarsColumns.CALENDAR_TIMEZONE);
  indexes.ownerAccountIndex = resultSet.getColumnIndex(CalendarsColumns.OWNER_ACCOUNT);
  indexes.isPrimaryIndex = resultSet.getColumnIndex(CalendarsColumns.IS_PRIMARY);
  indexes.canOrganizerRespondIndex = resultSet.getColumnIndex(CalendarsColumns.CAN_ORGANIZER_RESPOND);
  indexes.canModifyTimeZoneIndex = resultSet.getColumnIndex(CalendarsColumns.CAN_MODIFY_TIMEZONE);
  indexes.canPartiallyUpdateIndex = resultSet.getColumnIndex(CalendarsColumns.CAN_PARTIALLY_UPDATE);
  indexes.maxRemindersIndex = resultSet.getColumnIndex(CalendarsColumns.MAX_REMINDERS);
  indexes.allowedRemindersIndex = resultSet.getColumnIndex(CalendarsColumns.ALLOWED_REMINDERS);
  indexes.allowedAvailabilityIndex = resultSet.getColumnIndex(CalendarsColumns.ALLOWED_AVAILABILITY);
  indexes.allowedAttendeeTypesIndex = resultSet.getColumnIndex(CalendarsColumns.ALLOWED_ATTENDEE_TYPES);
  indexes.deletedIndex = resultSet.getColumnIndex(CalendarsColumns.DELETED);
  indexes.calendarTimeStampIndex = resultSet.getColumnIndex(CalendarsColumns.CALENDAR_TIME_STAMP);
  indexes.calSync1Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC1);
  indexes.calSync2Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC2);
  indexes.calSync3Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC3);
  indexes.calSync4Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC4);
  indexes.calSync5Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC5);
  indexes.calSync6Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC6);
  indexes.calSync7Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC7);
  indexes.calSync8Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC8);
  indexes.calSync9Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC9);
  indexes.calSync10Index = resultSet.getColumnIndex(CalendarsColumns.CAL_SYNC10);
  indexes.canReminderIndex = resultSet.getColumnIndex(CalendarsColumns.CAN_REMINDER);
  indexes.creatorIndex = resultSet.getColumnIndex(CalendarsColumns.CREATOR);
  return indexes;
}