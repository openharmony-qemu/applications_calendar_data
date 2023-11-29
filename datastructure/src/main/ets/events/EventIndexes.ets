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
import { EventColumns } from './EventColumns';

interface EventIndexesType {
  idIndex: number;
  syncIdIndex: number;
  dirtyIndex: number;
  mutatorsIndex: number;
  calendarTypeIndex: number;
  uuidIndex: number;
  imageTypeIndex: number;
  lastSyncedIndex: number;
  calendarIdIndex: number;
  titleIndex: number;
  eventLocationIndex: number;
  longitudeIndex: number;
  latitudeIndex: number;
  descriptionIndex: number;
  eventColorIndex: number;
  eventColorIndexIndex: number;
  eventStatusIndex: number;
  selfAttendeeStatusIndex: number;
  dtStartIndex: number;
  dtEndIndex: number;
  eventTimeZoneIndex: number;
  durationIndex: number;
  allDayIndex: number;
  accessLevelIndex: number;
  availabilityIndex: number;
  hasAlarmIndex: number;
  hasExtendedPropertiesIndex: number;
  rRuleIndex: number;
  rDateIndex: number;
  exRuleIndex: number;
  exDateIndex: number;
  originalIdIndex: number;
  originalSyncIdIndex: number;
  originalInstanceTimeIndex: number;
  originalAllDayIndex: number;
  lastDateIndex: number;
  eventTimeStampIndex: number;
  hasAttendeeDataIndex: number;
  guestsCanModifyIndex: number;
  guestsCanInviteOthersIndex: number;
  guestsCanSeeGuestsIndex: number;
  organizerIndex: number;
  isOrganizerIndex: number;
  deletedIndex: number;
  eventEndTimezoneIndex: number;
  customAppPackageIndex: number;
  customAppUriIndex: number;
  uid2445Index: number;
  versionIndex: number;
  eventUuidIndex: number;
  hwExtAlertTypeIndex: number;
  importantEventTypeIndex: number;
  serviceVerifiedIndex: number;
  serviceTypeIndex: number;
  serviceCpBzUriIndex: number;
  serviceCpMngUriIndex: number;
  serviceDescriptionIndex: number;
  serviceSupportMinVersionIndex: number;
  syncData1Index: number;
  syncData2Index: number;
  syncData3Index: number;
  syncData4Index: number;
  syncData5Index: number;
  syncData6Index: number;
  syncData7Index: number;
  syncData8Index: number;
  syncData9Index: number;
  syncData10Index: number;
  kvSyncedIndex: number;
  kvSyncTimeIndex: number;
  creatorIndex: number;
}

/**
 * the columns indexes for table Events
 *
 * @since 2022-05-28
 */
export class EventIndexes implements EventIndexesType {
  idIndex = 0;
  syncIdIndex = 0;
  dirtyIndex = 0;
  mutatorsIndex = 0;
  calendarTypeIndex = 0;
  uuidIndex = 0;
  imageTypeIndex = 0;
  lastSyncedIndex = 0;
  calendarIdIndex = 0;
  titleIndex = 0;
  eventLocationIndex = 0;
  longitudeIndex = 0;
  latitudeIndex = 0;
  descriptionIndex = 0;
  eventColorIndex = 0;
  eventColorIndexIndex = 0;
  eventStatusIndex = 0;
  selfAttendeeStatusIndex = 0;
  dtStartIndex = 0;
  dtEndIndex = 0;
  eventTimeZoneIndex = 0;
  durationIndex = 0;
  allDayIndex = 0;
  accessLevelIndex = 0;
  availabilityIndex = 0;
  hasAlarmIndex = 0;
  hasExtendedPropertiesIndex = 0;
  rRuleIndex = 0;
  rDateIndex = 0;
  exRuleIndex = 0;
  exDateIndex = 0;
  originalIdIndex = 0;
  originalSyncIdIndex = 0;
  originalInstanceTimeIndex = 0;
  originalAllDayIndex = 0;
  lastDateIndex = 0;
  eventTimeStampIndex = 0;
  hasAttendeeDataIndex = 0;
  guestsCanModifyIndex = 0;
  guestsCanInviteOthersIndex = 0;
  guestsCanSeeGuestsIndex = 0;
  organizerIndex = 0;
  isOrganizerIndex = 0;
  deletedIndex = 0;
  eventEndTimezoneIndex = 0;
  customAppPackageIndex = 0;
  customAppUriIndex = 0;
  uid2445Index = 0;
  versionIndex = 0;
  eventUuidIndex = 0;
  hwExtAlertTypeIndex = 0;
  importantEventTypeIndex = 0;
  serviceVerifiedIndex = 0;
  serviceTypeIndex = 0;
  serviceCpBzUriIndex = 0;
  serviceCpMngUriIndex = 0;
  serviceDescriptionIndex = 0;
  serviceSupportMinVersionIndex = 0;
  syncData1Index = 0;
  syncData2Index = 0;
  syncData3Index = 0;
  syncData4Index = 0;
  syncData5Index = 0;
  syncData6Index = 0;
  syncData7Index = 0;
  syncData8Index = 0;
  syncData9Index = 0;
  syncData10Index = 0;
  kvSyncedIndex = 0;
  kvSyncTimeIndex = 0;
  creatorIndex = 0;
}

/**
 * parse all indexes for table Events
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseIndexes(resultSet: data_rdb.ResultSet): EventIndexes | undefined {
  if (resultSet == null) {
    return undefined;
  }
  let indexes: EventIndexes = new EventIndexes();
  indexes.idIndex = resultSet.getColumnIndex(EventColumns.ID);
  indexes.syncIdIndex = resultSet.getColumnIndex(EventColumns.SYNC_ID);
  indexes.dirtyIndex = resultSet.getColumnIndex(EventColumns.DIRTY);
  indexes.mutatorsIndex = resultSet.getColumnIndex(EventColumns.MUTATORS);
  indexes.calendarTypeIndex = resultSet.getColumnIndex(EventColumns.EVENT_CALENDAR_TYPE);
  indexes.imageTypeIndex = resultSet.getColumnIndex(EventColumns.EVENT_IMAGE_TYPE);
  indexes.lastSyncedIndex = resultSet.getColumnIndex(EventColumns.LAST_SYNCED);
  indexes.calendarIdIndex = resultSet.getColumnIndex(EventColumns.CALENDAR_ID);
  indexes.titleIndex = resultSet.getColumnIndex(EventColumns.TITLE);
  indexes.eventLocationIndex = resultSet.getColumnIndex(EventColumns.EVENT_LOCATION);
  indexes.longitudeIndex = resultSet.getColumnIndex(EventColumns.LOCATION_LONGITUDE);
  indexes.latitudeIndex = resultSet.getColumnIndex(EventColumns.LOCATION_LATITUDE);
  indexes.descriptionIndex = resultSet.getColumnIndex(EventColumns.DESCRIPTION);
  indexes.eventColorIndex = resultSet.getColumnIndex(EventColumns.EVENT_COLOR);
  indexes.eventColorIndexIndex = resultSet.getColumnIndex(EventColumns.EVENT_COLOR_INDEX);
  indexes.eventStatusIndex = resultSet.getColumnIndex(EventColumns.EVENT_STATUS);
  indexes.selfAttendeeStatusIndex = resultSet.getColumnIndex(EventColumns.SELF_ATTENDEE_STATUS);
  indexes.dtStartIndex = resultSet.getColumnIndex(EventColumns.DTSTART);
  indexes.dtEndIndex = resultSet.getColumnIndex(EventColumns.DTEND);
  indexes.eventTimeZoneIndex = resultSet.getColumnIndex(EventColumns.EVENT_TIMEZONE);
  indexes.durationIndex = resultSet.getColumnIndex(EventColumns.DURATION);
  indexes.allDayIndex = resultSet.getColumnIndex(EventColumns.ALLDAY);
  indexes.accessLevelIndex = resultSet.getColumnIndex(EventColumns.ACCESS_LEVEL);
  indexes.availabilityIndex = resultSet.getColumnIndex(EventColumns.AVAILABILITY);
  indexes.hasAlarmIndex = resultSet.getColumnIndex(EventColumns.HAS_ALARM);
  indexes.hasExtendedPropertiesIndex = resultSet.getColumnIndex(EventColumns.HAS_EXTENDED_PROPERTIES);
  indexes.rRuleIndex = resultSet.getColumnIndex(EventColumns.RRULE);
  indexes.rDateIndex = resultSet.getColumnIndex(EventColumns.RDATE);
  indexes.exRuleIndex = resultSet.getColumnIndex(EventColumns.EXRULE);
  indexes.exDateIndex = resultSet.getColumnIndex(EventColumns.EXDATE);
  indexes.originalIdIndex = resultSet.getColumnIndex(EventColumns.ORIGINAL_ID);
  indexes.originalSyncIdIndex = resultSet.getColumnIndex(EventColumns.ORIGINAL_SYNC_ID);
  indexes.originalInstanceTimeIndex = resultSet.getColumnIndex(EventColumns.ORIGINAL_INSTANCE_TIME);
  indexes.originalAllDayIndex = resultSet.getColumnIndex(EventColumns.ORIGINAL_ALL_DAY);
  indexes.lastDateIndex = resultSet.getColumnIndex(EventColumns.LAST_DATE);
  indexes.eventTimeStampIndex = resultSet.getColumnIndex(EventColumns.EVENT_TIME_STAMP);
  indexes.hasAttendeeDataIndex = resultSet.getColumnIndex(EventColumns.HAS_ATTENDEE_DATE);
  indexes.guestsCanModifyIndex = resultSet.getColumnIndex(EventColumns.GUESTS_CAN_MODIFY);
  indexes.guestsCanInviteOthersIndex = resultSet.getColumnIndex(EventColumns.GUESTS_CAN_INVITE_OTHERS);
  indexes.guestsCanSeeGuestsIndex = resultSet.getColumnIndex(EventColumns.GUESTS_CAN_SEE_GUESTS);
  indexes.organizerIndex = resultSet.getColumnIndex(EventColumns.ORGANIZER);
  indexes.isOrganizerIndex = resultSet.getColumnIndex(EventColumns.IS_ORGANIZER);
  indexes.deletedIndex = resultSet.getColumnIndex(EventColumns.DELETED);
  indexes.eventEndTimezoneIndex = resultSet.getColumnIndex(EventColumns.EVENT_END_TIMEZONE);
  indexes.customAppPackageIndex = resultSet.getColumnIndex(EventColumns.CUSTOM_APP_PACKAGE);
  indexes.customAppUriIndex = resultSet.getColumnIndex(EventColumns.CUSTOM_APP_URI);
  indexes.uid2445Index = resultSet.getColumnIndex(EventColumns.UID2445);
  indexes.versionIndex = resultSet.getColumnIndex(EventColumns.VERSION);
  indexes.eventUuidIndex = resultSet.getColumnIndex(EventColumns.EVENT_UUID);
  indexes.hwExtAlertTypeIndex = resultSet.getColumnIndex(EventColumns.HWEXT_ALERT_TYPE);
  indexes.importantEventTypeIndex = resultSet.getColumnIndex(EventColumns.IMPORTANT_EVENT_TYPE);
  indexes.serviceVerifiedIndex = resultSet.getColumnIndex(EventColumns.SERVICE.SERVICE_VERIFIED);
  indexes.serviceTypeIndex = resultSet.getColumnIndex(EventColumns.SERVICE.SERVICE_TYPE);
  indexes.serviceCpBzUriIndex = resultSet.getColumnIndex(EventColumns.SERVICE.SERVICE_CP_BZ_URI);
  indexes.serviceCpMngUriIndex = resultSet.getColumnIndex(EventColumns.SERVICE.SERVICE_CP_MNG_URI);
  indexes.serviceDescriptionIndex = resultSet.getColumnIndex(EventColumns.SERVICE.SERVICE_DESCRIPTION);
  indexes.serviceSupportMinVersionIndex = resultSet.getColumnIndex(EventColumns.SERVICE.SERVICE_MIN_VERSION);
  indexes.syncData1Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA1);
  indexes.syncData2Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA2);
  indexes.syncData3Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA3);
  indexes.syncData4Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA4);
  indexes.syncData5Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA5);
  indexes.syncData6Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA6);
  indexes.syncData7Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA7);
  indexes.syncData8Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA8);
  indexes.syncData9Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA9);
  indexes.syncData10Index = resultSet.getColumnIndex(EventColumns.SYNC_DATA10);
  indexes.kvSyncedIndex = resultSet.getColumnIndex(EventColumns.KV_SYNC);
  indexes.kvSyncTimeIndex = resultSet.getColumnIndex(EventColumns.KV_SYNC_TIME);
  indexes.creatorIndex = resultSet.getColumnIndex(EventColumns.CREATOR);
  return indexes;
}