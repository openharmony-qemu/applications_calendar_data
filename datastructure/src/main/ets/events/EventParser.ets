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
import { EventColumns } from './EventColumns';
import { EventIndexes } from './EventIndexes';

/**
 * parse all columns for table Events
 *
 * @param resultSet the result from somewhere rdb.query
 */
export function parseEvents(resultSet: data_rdb.ResultSet): Events | undefined {
  if ((resultSet === null) || (resultSet === undefined)) {
    return undefined;
  }
  let event: Events = new Events();
  let dataResult: data_rdb.ValuesBucket = resultSet.getRow();
  event.creator = dataResult[EventColumns.CREATOR] as string ?? event.creator;
  event.title = dataResult[EventColumns.TITLE] as string ?? event.title;
  event.id = dataResult[EventColumns.ID] as number ?? event.id;
  event.syncId = dataResult[EventColumns.ID] as string ?? event.syncId;
  event.dirty = dataResult[EventColumns.DIRTY] as number ?? event.dirty;
  event.mutators = dataResult[EventColumns.MUTATORS] as string ?? event.mutators;
  event.calendarType = dataResult[EventColumns.EVENT_CALENDAR_TYPE] as number ?? event.calendarType;
  event.uuid = dataResult[EventColumns.UUID] as string ?? event.uuid;
  event.imageType = dataResult[EventColumns.EVENT_IMAGE_TYPE] as string ?? event.imageType;
  event.lastSynced = dataResult[EventColumns.LAST_SYNCED] as number ?? event.lastSynced;
  event.calendarId = dataResult[EventColumns.CALENDAR_ID] as number ?? event.calendarId;
  event.eventLocation = dataResult[EventColumns.EVENT_LOCATION] as string ?? event.eventLocation;
  event.longitude = dataResult[EventColumns.LOCATION_LONGITUDE] as string ?? event.longitude;
  event.latitude = dataResult[EventColumns.LOCATION_LATITUDE] as string ?? event.latitude;
  event.description = dataResult[EventColumns.DESCRIPTION] as string ?? event.description;
  event.eventColor = dataResult[EventColumns.EVENT_COLOR] as number ?? event.eventColor;
  event.eventColorIndex = dataResult[EventColumns.EVENT_COLOR_INDEX] as string ?? event.eventColorIndex;
  event.eventStatus = dataResult[EventColumns.EVENT_STATUS] as number ?? event.eventStatus;
  event.selfAttendeeStatus = dataResult[EventColumns.SELF_ATTENDEE_STATUS] as number ?? event.selfAttendeeStatus;
  event.dtStart = dataResult[EventColumns.DTSTART] as number ?? event.dtStart;
  event.dtEnd = dataResult[EventColumns.DTEND] as number ?? event.dtEnd;
  event.eventTimeZone = dataResult[EventColumns.EVENT_TIMEZONE] as string ?? event.eventTimeZone;
  event.duration = dataResult[EventColumns.DURATION] as string ?? event.duration;
  event.allDay = dataResult[EventColumns.ALLDAY] as number ?? event.allDay;
  event.accessLevel = dataResult[EventColumns.ACCESS_LEVEL] as number ?? event.accessLevel;
  event.availability = dataResult[EventColumns.AVAILABILITY] as number ?? event.availability;
  event.hasAlarm = dataResult[EventColumns.HAS_ALARM] as number ?? event.hasAlarm;
  event.hasExtendedProperties =
    dataResult[EventColumns.HAS_EXTENDED_PROPERTIES] as number ?? event.hasExtendedProperties;
  event.rRule = dataResult[EventColumns.RRULE] as string ?? event.rRule;
  event.rDate = dataResult[EventColumns.RDATE] as string ?? event.rDate;
  event.exRule = dataResult[EventColumns.EXRULE] as string ?? event.exRule;
  event.exDate = dataResult[EventColumns.EXDATE] as string ?? event.exDate;
  event.originalId = dataResult[EventColumns.ORIGINAL_ID] as number ?? event.originalId;
  event.originalSyncId = dataResult[EventColumns.ORIGINAL_SYNC_ID] as string ?? event.originalSyncId;
  event.originalInstanceTime = dataResult[EventColumns.ORIGINAL_INSTANCE_TIME] as number ?? event.originalInstanceTime;
  event.originalAllDay = dataResult[EventColumns.ORIGINAL_ALL_DAY] as number ?? event.originalAllDay;
  event.lastDate = dataResult[EventColumns.LAST_DATE] as number ?? event.lastDate;
  event.eventTimeStamp = dataResult[EventColumns.EVENT_TIME_STAMP] as number ?? event.eventTimeStamp;
  event.hasAttendeeData = dataResult[EventColumns.HAS_ATTENDEE_DATE] as number ?? event.hasAttendeeData;
  event.guestsCanModify = dataResult[EventColumns.GUESTS_CAN_MODIFY] as number ?? event.guestsCanModify;
  event.guestsCanInviteOthers = dataResult[EventColumns.GUESTS_CAN_INVITE_OTHERS] as number ?? event.guestsCanInviteOthers;
  event.guestsCanSeeGuests = dataResult[EventColumns.GUESTS_CAN_SEE_GUESTS] as number ?? event.guestsCanSeeGuests;
  event.organizer = dataResult[EventColumns.ORGANIZER] as string ?? event.organizer;
  event.isOrganizer = dataResult[EventColumns.IS_ORGANIZER] as number ?? event.isOrganizer;
  event.deleted = dataResult[EventColumns.DELETED] as number ?? event.deleted;
  event.eventEndTimezone = dataResult[EventColumns.EVENT_END_TIMEZONE] as string ?? event.eventEndTimezone;
  event.customAppPackage = dataResult[EventColumns.CUSTOM_APP_PACKAGE] as string ?? event.customAppPackage;
  event.customAppUri = dataResult[EventColumns.CUSTOM_APP_URI] as string ?? event.customAppUri;
  event.uid2445 = dataResult[EventColumns.UID2445] as string ?? event.uid2445;
  event.version = dataResult[EventColumns.VERSION] as number ?? event.version;
  event.eventUuid = dataResult[EventColumns.EVENT_UUID] as string ?? event.eventUuid;
  event.hwExtAlertType = dataResult[EventColumns.HWEXT_ALERT_TYPE] as number ?? event.hwExtAlertType;
  event.importantEventType = dataResult[EventColumns.IMPORTANT_EVENT_TYPE] as number ?? event.importantEventType;
  event.serviceVerified = dataResult[EventColumns.SERVICE.SERVICE_VERIFIED] as number ?? event.serviceVerified;
  event.serviceType = dataResult[EventColumns.SERVICE.SERVICE_TYPE] as string ?? event.serviceType;
  event.serviceCpBzUri = dataResult[EventColumns.SERVICE.SERVICE_CP_BZ_URI] as string ?? event.serviceCpBzUri;
  event.serviceCpMngUri = dataResult[EventColumns.SERVICE.SERVICE_CP_MNG_URI] as string ?? event.serviceCpMngUri;
  event.serviceDescription = dataResult[EventColumns.SERVICE.SERVICE_DESCRIPTION] as string ?? event.serviceDescription;
  event.serviceSupportMinVersion =
    dataResult[EventColumns.SERVICE.SERVICE_MIN_VERSION] as number ?? event.serviceSupportMinVersion;

  event.syncData1 = dataResult[EventColumns.SYNC_DATA1] as string ?? event.syncData1;
  event.syncData2 = dataResult[EventColumns.SYNC_DATA2] as string ?? event.syncData2;
  event.syncData3 = dataResult[EventColumns.SYNC_DATA3] as string ?? event.syncData3;
  event.syncData4 = dataResult[EventColumns.SYNC_DATA4] as string ?? event.syncData4;
  event.syncData5 = dataResult[EventColumns.SYNC_DATA5] as string ?? event.syncData5;
  event.syncData6 = dataResult[EventColumns.SYNC_DATA6] as string ?? event.syncData6;
  event.syncData7 = dataResult[EventColumns.SYNC_DATA7] as string ?? event.syncData7;
  event.syncData8 = dataResult[EventColumns.SYNC_DATA8] as string ?? event.syncData8;
  event.syncData9 = dataResult[EventColumns.SYNC_DATA9] as string ?? event.syncData9;
  event.syncData10 = dataResult[EventColumns.SYNC_DATA10] as string ?? event.syncData10;
  event.kvSynced = dataResult[EventColumns.KV_SYNC] as number ?? event.kvSynced;
  event.kvSyncTime = dataResult[EventColumns.KV_SYNC_TIME] as number ?? event.kvSyncTime;
  event.identifier = dataResult[EventColumns.IDENTIFIER] as string ?? event.identifier;
  event.calendarUuid = dataResult[EventColumns.CALENDAR_UUID] as string ?? event.calendarUuid;
  return event;
}

export function parseEventByIndex(resultSet: data_rdb.ResultSet, indexes: EventIndexes | undefined):
  Events | undefined {
  if (!resultSet || !indexes) {
    return undefined;
  }
  let event: Events = new Events();
  event.id = parseLong(resultSet, indexes.idIndex, event.id);
  event.syncId = parseString(resultSet, indexes.syncIdIndex, event.syncId);
  event.dirty = parseLong(resultSet, indexes.dirtyIndex, event.dirty);
  event.mutators = parseString(resultSet, indexes.mutatorsIndex, event.mutators);
  event.calendarType = parseLong(resultSet, indexes.calendarTypeIndex, event.calendarType);
  event.uuid = parseString(resultSet, indexes.uuidIndex, event.uuid);
  event.imageType = parseString(resultSet, indexes.imageTypeIndex, event.imageType);
  event.lastSynced = parseLong(resultSet, indexes.lastSyncedIndex, event.lastSynced);
  event.calendarId = parseLong(resultSet, indexes.calendarIdIndex, event.calendarId);
  event.calendarUuid = parseString(resultSet, indexes.calendarUuidIndex, event.calendarUuid);
  event.title = parseString(resultSet, indexes.titleIndex, event.title);
  event.eventLocation = parseString(resultSet, indexes.eventLocationIndex, event.eventLocation);
  event.longitude = parseString(resultSet, indexes.longitudeIndex, event.longitude);
  event.latitude = parseString(resultSet, indexes.latitudeIndex, event.latitude);
  event.description = parseString(resultSet, indexes.descriptionIndex, event.description);
  event.eventColor = parseLong(resultSet, indexes.eventColorIndex, event.eventColor);
  event.eventColorIndex = parseString(resultSet, indexes.eventColorIndexIndex, event.eventColorIndex);
  event.eventStatus = parseLong(resultSet, indexes.eventStatusIndex, event.eventStatus);
  event.selfAttendeeStatus = parseLong(resultSet, indexes.selfAttendeeStatusIndex, event.selfAttendeeStatus);
  event.dtStart = parseLong(resultSet, indexes.dtStartIndex, event.dtStart);
  event.dtEnd = parseLong(resultSet, indexes.dtEndIndex, event.dtEnd);
  event.eventTimeZone = parseString(resultSet, indexes.eventTimeZoneIndex, event.eventTimeZone);
  event.duration = parseString(resultSet, indexes.durationIndex, event.duration);
  event.allDay = parseLong(resultSet, indexes.allDayIndex, event.allDay);
  event.accessLevel = parseLong(resultSet, indexes.accessLevelIndex, event.accessLevel);
  event.availability = parseLong(resultSet, indexes.availabilityIndex, event.availability);
  event.hasAlarm = parseLong(resultSet, indexes.hasAlarmIndex, event.hasAlarm);
  event.hasExtendedProperties = parseLong(resultSet, indexes.hasExtendedPropertiesIndex, event.hasExtendedProperties);
  event.rRule = parseString(resultSet, indexes.rRuleIndex, event.rRule);
  event.rDate = parseString(resultSet, indexes.rDateIndex, event.rDate);
  event.exRule = parseString(resultSet, indexes.exRuleIndex, event.exRule);
  event.exDate = parseString(resultSet, indexes.exDateIndex, event.exDate);
  event.originalId = parseLong(resultSet, indexes.originalIdIndex, event.originalId);
  event.originalSyncId = parseString(resultSet, indexes.originalSyncIdIndex, event.originalSyncId);
  event.originalInstanceTime = parseLong(resultSet, indexes.originalInstanceTimeIndex, event.originalInstanceTime);
  event.originalAllDay = parseLong(resultSet, indexes.originalAllDayIndex, event.originalAllDay);
  event.lastDate = parseLong(resultSet, indexes.lastDateIndex, event.lastDate);
  event.eventTimeStamp = parseLong(resultSet, indexes.eventTimeStampIndex, event.eventTimeStamp);
  event.hasAttendeeData = parseLong(resultSet, indexes.hasAttendeeDataIndex, event.hasAttendeeData);
  event.guestsCanModify = parseLong(resultSet, indexes.guestsCanModifyIndex, event.guestsCanModify);
  event.guestsCanInviteOthers = parseLong(resultSet, indexes.guestsCanInviteOthersIndex, event.guestsCanInviteOthers);
  event.guestsCanSeeGuests = parseLong(resultSet, indexes.guestsCanSeeGuestsIndex, event.guestsCanSeeGuests);
  event.organizer = parseString(resultSet, indexes.organizerIndex, event.organizer);
  event.isOrganizer = parseLong(resultSet, indexes.isOrganizerIndex, event.isOrganizer);
  event.deleted = parseLong(resultSet, indexes.deletedIndex, event.deleted);
  event.eventEndTimezone = parseString(resultSet, indexes.eventEndTimezoneIndex, event.eventEndTimezone);
  event.customAppPackage = parseString(resultSet, indexes.customAppPackageIndex, event.customAppPackage);
  event.customAppUri = parseString(resultSet, indexes.customAppUriIndex, event.customAppUri);
  event.uid2445 = parseString(resultSet, indexes.uid2445Index, event.uid2445);
  event.version = parseLong(resultSet, indexes.versionIndex, event.version);
  event.eventUuid = parseString(resultSet, indexes.eventUuidIndex, event.eventUuid);
  event.hwExtAlertType = parseLong(resultSet, indexes.hwExtAlertTypeIndex, event.hwExtAlertType);
  event.importantEventType = parseLong(resultSet, indexes.importantEventTypeIndex, event.importantEventType);
  parseSyncDataByIndex(event, resultSet, indexes);
  parseEventByIndexSub(event, resultSet, indexes);
  return event;
}

function parseSyncDataByIndex(event: Events, resultSet: data_rdb.ResultSet, indexes: EventIndexes) {
  event.syncData1 = parseString(resultSet, indexes.syncData1Index, event.syncData1);
  event.syncData2 = parseString(resultSet, indexes.syncData2Index, event.syncData2);
  event.syncData3 = parseString(resultSet, indexes.syncData3Index, event.syncData3);
  event.syncData4 = parseString(resultSet, indexes.syncData4Index, event.syncData4);
  event.syncData5 = parseString(resultSet, indexes.syncData5Index, event.syncData5);
  event.syncData6 = parseString(resultSet, indexes.syncData6Index, event.syncData6);
  event.syncData7 = parseString(resultSet, indexes.syncData7Index, event.syncData7);
  event.syncData8 = parseString(resultSet, indexes.syncData8Index, event.syncData8);
  event.syncData9 = parseString(resultSet, indexes.syncData9Index, event.syncData9);
  event.syncData10 = parseString(resultSet, indexes.syncData10Index, event.syncData10);
}

function parseEventByIndexSub(event: Events, resultSet: data_rdb.ResultSet, indexes: EventIndexes) {
  event.kvSynced = parseLong(resultSet, indexes.kvSyncedIndex, event.kvSynced);
  event.kvSyncTime = parseLong(resultSet, indexes.kvSyncTimeIndex, event.kvSyncTime);
  event.creator = parseString(resultSet, indexes.creatorIndex, event.creator);
  event.identifier = parseString(resultSet, indexes.identifierIndex, event.identifier);
}

function parseLong(resultSet: data_rdb.ResultSet, index: number, defaultValue: number): number {
  return (index >= 0) ? resultSet.getLong(index) : defaultValue;
}

function parseString(resultSet: data_rdb.ResultSet, index: number, defaultValue: string): string {
  return (index >= 0) ? resultSet.getString(index) : defaultValue;
}