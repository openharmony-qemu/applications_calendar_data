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
import { Calendars } from './Calendars';
import { CalendarsIndexes } from './CalendarsIndexes';

/**
 * parse all columns for table Calendars
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseCalendars(resultSet: data_rdb.ResultSet, indexes: CalendarsIndexes | undefined): Calendars | undefined {
  if (resultSet === null || resultSet === undefined || indexes === null || indexes === undefined) {
    return undefined;
  }
  let calendars: Calendars = new Calendars();
  if (indexes.idIndex >= 0) {
    calendars.id = resultSet.getLong(indexes.idIndex);
  }
  if (indexes.accountNameIndex >= 0) {
    calendars.accountName = resultSet.getString(indexes.accountNameIndex);
  }
  if (indexes.accountTypeIndex >= 0) {
    calendars.accountType = resultSet.getString(indexes.accountTypeIndex);
  }
  if (indexes.syncIdIndex >= 0) {
    calendars.syncId = resultSet.getString(indexes.syncIdIndex);
  }
  if (indexes.dirtyIndex >= 0) {
    calendars.dirty = resultSet.getLong(indexes.dirtyIndex);
  }
  if (indexes.mutatorsIndex >= 0) {
    calendars.mutators = resultSet.getString(indexes.mutatorsIndex);
  }
  if (indexes.nameIndex >= 0) {
    calendars.name = resultSet.getString(indexes.nameIndex);
  }
  if (indexes.calendarDisplayNameIndex >= 0) {
    calendars.calendarDisplayName = resultSet.getString(indexes.calendarDisplayNameIndex);
  }
  if (indexes.calendarColorIndex >= 0) {
    calendars.calendarColor = resultSet.getLong(indexes.calendarColorIndex);
  }
  if (indexes.calendarColorIndexIndex >= 0) {
    calendars.calendarColorIndex = resultSet.getString(indexes.calendarColorIndexIndex);
  }
  if (indexes.calendarAccessLevelIndex >= 0) {
    calendars.calendarAccessLevel = resultSet.getLong(indexes.calendarAccessLevelIndex);
  }
  if (indexes.visibleIndex >= 0) {
    calendars.visible = resultSet.getLong(indexes.visibleIndex);
  }
  if (indexes.syncEventsIndex >= 0) {
    calendars.syncEvents = resultSet.getLong(indexes.syncEventsIndex);
  }
  if (indexes.calendarLocationIndex >= 0) {
    calendars.calendarLocation = resultSet.getString(indexes.calendarLocationIndex);
  }
  if (indexes.calendarTimezoneIndex >= 0) {
    calendars.calendarTimezone = resultSet.getString(indexes.calendarTimezoneIndex);
  }
  if (indexes.ownerAccountIndex >= 0) {
    calendars.ownerAccount = resultSet.getString(indexes.ownerAccountIndex);
  }
  if (indexes.isPrimaryIndex >= 0) {
    calendars.isPrimary = resultSet.getLong(indexes.isPrimaryIndex);
  }
  if (indexes.canOrganizerRespondIndex >= 0) {
    calendars.canOrganizerRespond = resultSet.getLong(indexes.canOrganizerRespondIndex);
  }
  if (indexes.canModifyTimeZoneIndex >= 0) {
    calendars.canModifyTimeZone = resultSet.getLong(indexes.canModifyTimeZoneIndex);
  }
  if (indexes.canPartiallyUpdateIndex >= 0) {
    calendars.canPartiallyUpdate = resultSet.getLong(indexes.canPartiallyUpdateIndex);
  }
  if (indexes.maxRemindersIndex >= 0) {
    calendars.maxReminders = resultSet.getLong(indexes.maxRemindersIndex);
  }
  if (indexes.allowedRemindersIndex >= 0) {
    calendars.allowedReminders = resultSet.getString(indexes.allowedRemindersIndex);
  }
  if (indexes.allowedAvailabilityIndex >= 0) {
    calendars.allowedAvailability = resultSet.getString(indexes.allowedAvailabilityIndex);
  }
  if (indexes.allowedAttendeeTypesIndex >= 0) {
    calendars.allowedAttendeeTypes = resultSet.getString(indexes.allowedAttendeeTypesIndex);
  }
  if (indexes.deletedIndex >= 0) {
    calendars.deleted = resultSet.getLong(indexes.deletedIndex);
  }
  if (indexes.calendarTimeStampIndex >= 0) {
    calendars.calendarTimeStamp = resultSet.getLong(indexes.calendarTimeStampIndex);
  }
  if (indexes.calSync1Index >= 0) {
    calendars.calSync1 = resultSet.getString(indexes.calSync1Index);
  }
  if (indexes.calSync2Index >= 0) {
    calendars.calSync2 = resultSet.getString(indexes.calSync2Index);
  }
  if (indexes.calSync3Index >= 0) {
    calendars.calSync3 = resultSet.getString(indexes.calSync3Index);
  }
  if (indexes.calSync4Index >= 0) {
    calendars.calSync4 = resultSet.getString(indexes.calSync4Index);
  }
  if (indexes.calSync5Index >= 0) {
    calendars.calSync5 = resultSet.getString(indexes.calSync5Index);
  }
  if (indexes.calSync6Index >= 0) {
    calendars.calSync6 = resultSet.getString(indexes.calSync6Index);
  }
  if (indexes.calSync7Index >= 0) {
    calendars.calSync7 = resultSet.getString(indexes.calSync7Index);
  }
  if (indexes.calSync8Index >= 0) {
    calendars.calSync8 = resultSet.getString(indexes.calSync8Index);
  }
  if (indexes.calSync9Index >= 0) {
    calendars.calSync9 = resultSet.getString(indexes.calSync9Index);
  }
  if (indexes.calSync10Index >= 0) {
    calendars.calSync10 = resultSet.getString(indexes.calSync10Index);
  }
  if (indexes.canReminderIndex >= 0) {
    calendars.canReminder = resultSet.getLong(indexes.canReminderIndex);
  }
  if (indexes.creatorIndex >= 0) {
    calendars.creator = resultSet.getString(indexes.creatorIndex);
  }
  return calendars;
}