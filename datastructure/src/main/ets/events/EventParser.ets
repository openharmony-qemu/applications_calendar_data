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
import { Events } from './Events';
import { EventIndexes } from './EventIndexes';

/**
 * parse all columns for table Events
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseEvents(resultSet: data_rdb.ResultSet, indexes: EventIndexes | undefined): Events | undefined {
  if (resultSet === null || resultSet === undefined || indexes === null || indexes === undefined) {
    return undefined;
  }
  let event: Events = new Events();
  if (indexes.idIndex >= 0) {
    event.id = resultSet.getLong(indexes.idIndex);
  }
  if (indexes.syncIdIndex >= 0) {
    event.syncId = resultSet.getString(indexes.syncIdIndex);
  }
  if (indexes.dirtyIndex >= 0) {
    event.dirty = resultSet.getLong(indexes.dirtyIndex);
  }
  if (indexes.mutatorsIndex >= 0) {
    event.mutators = resultSet.getString(indexes.mutatorsIndex);
  }
  if (indexes.calendarTypeIndex >= 0) {
    event.calendarType = resultSet.getLong(indexes.calendarTypeIndex);
  }
  if (indexes.imageTypeIndex >= 0) {
    event.imageType = resultSet.getString(indexes.imageTypeIndex);
  }
  if (indexes.lastSyncedIndex >= 0) {
    event.lastSynced = resultSet.getLong(indexes.lastSyncedIndex);
  }
  if (indexes.calendarIdIndex >= 0) {
    event.calendarId = resultSet.getLong(indexes.calendarIdIndex);
  }
  if (indexes.titleIndex >= 0) {
    event.title = resultSet.getString(indexes.titleIndex);
  }
  if (indexes.eventLocationIndex >= 0) {
    event.eventLocation = resultSet.getString(indexes.eventLocationIndex);
  }
  if (indexes.longitudeIndex >= 0) {
    event.longitude = resultSet.getString(indexes.longitudeIndex);
  }
  if (indexes.latitudeIndex >= 0) {
    event.latitude = resultSet.getString(indexes.latitudeIndex);
  }
  if (indexes.descriptionIndex >= 0) {
    event.description = resultSet.getString(indexes.descriptionIndex);
  }
  if (indexes.eventColorIndex >= 0) {
    event.eventColor = resultSet.getLong(indexes.eventColorIndex);
  }
  if (indexes.eventColorIndexIndex >= 0) {
    event.eventColorIndex = resultSet.getString(indexes.eventColorIndexIndex);
  }
  if (indexes.eventStatusIndex >= 0) {
    event.eventStatus = resultSet.getLong(indexes.eventStatusIndex);
  }
  if (indexes.selfAttendeeStatusIndex >= 0) {
    event.selfAttendeeStatus = resultSet.getLong(indexes.selfAttendeeStatusIndex);
  }
  if (indexes.dtStartIndex >= 0) {
    event.dtStart = resultSet.getLong(indexes.dtStartIndex);
  }
  if (indexes.dtEndIndex >= 0) {
    event.dtEnd = resultSet.getLong(indexes.dtEndIndex);
  }
  if (indexes.eventTimeZoneIndex >= 0) {
    event.eventTimeZone = resultSet.getString(indexes.eventTimeZoneIndex);
  }
  if (indexes.durationIndex >= 0) {
    event.duration = resultSet.getString(indexes.durationIndex);
  }
  if (indexes.allDayIndex >= 0) {
    event.allDay = resultSet.getLong(indexes.allDayIndex);
  }
  if (indexes.accessLevelIndex >= 0) {
    event.accessLevel = resultSet.getLong(indexes.accessLevelIndex);
  }
  if (indexes.availabilityIndex >= 0) {
    event.availability = resultSet.getLong(indexes.availabilityIndex);
  }
  if (indexes.hasAlarmIndex >= 0) {
    event.hasAlarm = resultSet.getLong(indexes.hasAlarmIndex);
  }
  if (indexes.hasExtendedPropertiesIndex >= 0) {
    event.hasExtendedProperties = resultSet.getLong(indexes.hasExtendedPropertiesIndex);
  }
  if (indexes.rRuleIndex >= 0) {
    event.rRule = resultSet.getString(indexes.rRuleIndex);
  }
  if (indexes.rDateIndex >= 0) {
    event.rDate = resultSet.getString(indexes.rDateIndex);
  }
  if (indexes.exRuleIndex >= 0) {
    event.exRule = resultSet.getString(indexes.exRuleIndex);
  }
  if (indexes.exDateIndex >= 0) {
    event.exDate = resultSet.getString(indexes.exDateIndex);
  }
  if (indexes.originalIdIndex >= 0) {
    event.originalId = resultSet.getLong(indexes.originalIdIndex);
  }
  if (indexes.originalSyncIdIndex >= 0) {
    event.originalSyncId = resultSet.getString(indexes.originalSyncIdIndex);
  }
  if (indexes.originalInstanceTimeIndex >= 0) {
    event.originalInstanceTime = resultSet.getLong(indexes.originalInstanceTimeIndex);
  }
  if (indexes.originalAllDayIndex >= 0) {
    event.originalAllDay = resultSet.getLong(indexes.originalAllDayIndex);
  }
  if (indexes.lastDateIndex >= 0) {
    event.lastDate = resultSet.getLong(indexes.lastDateIndex);
  }
  if (indexes.eventTimeStampIndex >= 0) {
    event.eventTimeStamp = resultSet.getLong(indexes.eventTimeStampIndex);
  }
  if (indexes.hasAttendeeDataIndex >= 0) {
    event.hasAttendeeData = resultSet.getLong(indexes.hasAttendeeDataIndex);
  }
  if (indexes.guestsCanModifyIndex >= 0) {
    event.guestsCanModify = resultSet.getLong(indexes.guestsCanModifyIndex);
  }
  if (indexes.guestsCanInviteOthersIndex >= 0) {
    event.guestsCanInviteOthers = resultSet.getLong(indexes.guestsCanInviteOthersIndex);
  }
  if (indexes.guestsCanSeeGuestsIndex >= 0) {
    event.guestsCanSeeGuests = resultSet.getLong(indexes.guestsCanSeeGuestsIndex);
  }
  if (indexes.organizerIndex >= 0) {
    event.organizer = resultSet.getString(indexes.organizerIndex);
  }
  if (indexes.isOrganizerIndex >= 0) {
    event.isOrganizer = resultSet.getLong(indexes.isOrganizerIndex);
  }
  if (indexes.deletedIndex >= 0) {
    event.deleted = resultSet.getLong(indexes.deletedIndex);
  }
  if (indexes.eventEndTimezoneIndex >= 0) {
    event.eventEndTimezone = resultSet.getString(indexes.eventEndTimezoneIndex);
  }
  if (indexes.customAppPackageIndex >= 0) {
    event.customAppPackage = resultSet.getString(indexes.customAppPackageIndex);
  }
  if (indexes.customAppUriIndex >= 0) {
    event.customAppUri = resultSet.getString(indexes.customAppUriIndex);
  }
  if (indexes.uid2445Index >= 0) {
    event.uid2445 = resultSet.getString(indexes.uid2445Index);
  }
  if (indexes.versionIndex >= 0) {
    event.version = resultSet.getLong(indexes.versionIndex);
  }
  if (indexes.eventUuidIndex >= 0) {
    event.eventUuid = resultSet.getString(indexes.eventUuidIndex);
  }
  if (indexes.hwExtAlertTypeIndex >= 0) {
    event.hwExtAlertType = resultSet.getLong(indexes.hwExtAlertTypeIndex);
  }
  if (indexes.importantEventTypeIndex >= 0) {
    event.importantEventType = resultSet.getLong(indexes.importantEventTypeIndex);
  }
  if (indexes.serviceVerifiedIndex >= 0) {
    event.serviceVerified = resultSet.getLong(indexes.serviceVerifiedIndex);
  }
  if (indexes.serviceTypeIndex >= 0) {
    event.serviceType = resultSet.getString(indexes.serviceTypeIndex);
  }
  if (indexes.serviceCpBzUriIndex >= 0) {
    event.serviceCpBzUri = resultSet.getString(indexes.serviceCpBzUriIndex);
  }
  if (indexes.serviceCpMngUriIndex >= 0) {
    event.serviceCpMngUri = resultSet.getString(indexes.serviceCpMngUriIndex);
  }
  if (indexes.serviceDescriptionIndex >= 0) {
    event.serviceDescription = resultSet.getString(indexes.serviceDescriptionIndex);
  }
  if (indexes.serviceSupportMinVersionIndex >= 0) {
    event.serviceSupportMinVersion = resultSet.getLong(indexes.serviceSupportMinVersionIndex);
  }
  if (indexes.syncData1Index >= 0) {
    event.syncData1 = resultSet.getString(indexes.syncData1Index);
  }
  if (indexes.syncData2Index >= 0) {
    event.syncData1 = resultSet.getString(indexes.syncData2Index);
  }
  if (indexes.syncData3Index >= 0) {
    event.syncData3 = resultSet.getString(indexes.syncData3Index);
  }
  if (indexes.syncData4Index >= 0) {
    event.syncData4 = resultSet.getString(indexes.syncData4Index);
  }
  if (indexes.syncData5Index >= 0) {
    event.syncData5 = resultSet.getString(indexes.syncData5Index);
  }
  if (indexes.syncData6Index >= 0) {
    event.syncData6 = resultSet.getString(indexes.syncData6Index);
  }
  if (indexes.syncData7Index >= 0) {
    event.syncData7 = resultSet.getString(indexes.syncData7Index);
  }
  if (indexes.syncData8Index >= 0) {
    event.syncData8 = resultSet.getString(indexes.syncData8Index);
  }
  if (indexes.syncData9Index >= 0) {
    event.syncData9 = resultSet.getString(indexes.syncData9Index);
  }
  if (indexes.syncData10Index >= 0) {
    event.syncData10 = resultSet.getString(indexes.syncData10Index);
  }
  if (indexes.kvSyncedIndex >= 0) {
    event.kvSynced = resultSet.getLong(indexes.kvSyncedIndex);
  }
  if (indexes.kvSyncTimeIndex >= 0) {
    event.kvSyncTime = resultSet.getLong(indexes.kvSyncTimeIndex);
  }
  if (indexes.creatorIndex >= 0) {
    event.creator = resultSet.getString(indexes.creatorIndex);
  }
  return event;
}