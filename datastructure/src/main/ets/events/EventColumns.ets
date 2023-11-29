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

import { Constants } from '../Constants';

interface serviceType {
  SERVICE_VERIFIED: string;
  SERVICE_TYPE: string;
  SERVICE_CP_BZ_URI: string;
  SERVICE_CP_MNG_URI: string;
  SERVICE_DESCRIPTION: string;
  SERVICE_MIN_VERSION: string;
}

interface eventColumnsType {
  TABLE_NAME: string,
  ID: string,
  SYNC_ID: string,
  DIRTY: string,
  MUTATORS: string,
  EVENT_CALENDAR_TYPE: string,
  EVENT_IMAGE_TYPE: string,
  LAST_SYNCED: string,
  CALENDAR_ID: string,
  TITLE: string,
  EVENT_LOCATION: string,
  LOCATION_LONGITUDE: string,
  LOCATION_LATITUDE: string,
  DESCRIPTION: string,
  EVENT_COLOR: string,
  EVENT_COLOR_INDEX: string,
  EVENT_STATUS: string,
  SELF_ATTENDEE_STATUS: string,
  DTSTART: string,
  DTEND: string,
  EVENT_TIMEZONE: string,
  DURATION: string,
  ALLDAY: string,
  ACCESS_LEVEL: string,
  AVAILABILITY: string,
  HAS_ALARM: string,
  HAS_EXTENDED_PROPERTIES: string,
  RRULE: string,
  RDATE: string,
  EXRULE: string,
  EXDATE: string,
  ORIGINAL_ID: string,
  ORIGINAL_SYNC_ID: string,
  ORIGINAL_INSTANCE_TIME: string,
  ORIGINAL_ALL_DAY: string,
  LAST_DATE: string,
  EVENT_TIME_STAMP: string,
  HAS_ATTENDEE_DATE: string,
  GUESTS_CAN_MODIFY: string,
  GUESTS_CAN_INVITE_OTHERS: string,
  GUESTS_CAN_SEE_GUESTS: string,
  ORGANIZER: string,
  IS_ORGANIZER: string,
  DELETED: string,
  EVENT_END_TIMEZONE: string,
  CUSTOM_APP_PACKAGE: string,
  CUSTOM_APP_URI: string,
  UID2445: string,
  VERSION: string,
  EVENT_UUID: string,
  HWEXT_ALERT_TYPE: string,
  IMPORTANT_EVENT_TYPE: string,
  SYNC_DATA1: string,
  SYNC_DATA2: string,
  SYNC_DATA3: string,
  SYNC_DATA4: string,
  SYNC_DATA5: string,
  SYNC_DATA6: string,
  SYNC_DATA7: string,
  SYNC_DATA8: string,
  SYNC_DATA9: string,
  SYNC_DATA10: string,
  KV_SYNC: string,
  KV_SYNC_TIME: string,
  CREATOR: string,
  SERVICE: serviceType
}

/**
 * the const of table Events
 *
 * @since 2022-05-28
 */
export const EventColumns: eventColumnsType = {
  TABLE_NAME: 'Events',
  ID: '_id',
  SYNC_ID: '_sync_id',
  DIRTY: 'dirty',
  MUTATORS: 'mutators',
  EVENT_CALENDAR_TYPE: 'event_calendar_type',
  EVENT_IMAGE_TYPE: 'event_image_type',
  LAST_SYNCED: 'lastSynced',
  CALENDAR_ID: 'calendar_id',
  TITLE: 'title',
  EVENT_LOCATION: 'eventLocation',
  LOCATION_LONGITUDE: 'location_longitude',
  LOCATION_LATITUDE: 'location_latitude',
  DESCRIPTION: 'description',
  EVENT_COLOR: 'eventColor',
  EVENT_COLOR_INDEX: 'eventColor_index',
  EVENT_STATUS: 'eventStatus',
  SELF_ATTENDEE_STATUS: 'selfAttendeeStatus',
  DTSTART: 'dtstart',
  DTEND: 'dtend',
  EVENT_TIMEZONE: 'eventTimezone',
  DURATION: 'duration',
  ALLDAY: 'allDay',
  ACCESS_LEVEL: 'accessLevel',
  AVAILABILITY: 'availability',
  HAS_ALARM: 'hasAlarm',
  HAS_EXTENDED_PROPERTIES: 'hasExtendedProperties',
  RRULE: 'rrule',
  RDATE: 'rdate',
  EXRULE: 'exrule',
  EXDATE: 'exdate',
  ORIGINAL_ID: 'original_id',
  ORIGINAL_SYNC_ID: 'original_sync_id',
  ORIGINAL_INSTANCE_TIME: 'originalInstanceTime',
  ORIGINAL_ALL_DAY: 'originalAllDay',
  LAST_DATE: 'lastDate',
  EVENT_TIME_STAMP: 'event_time_stamp',
  HAS_ATTENDEE_DATE: 'hasAttendeeData',
  GUESTS_CAN_MODIFY: 'guestsCanModify',
  GUESTS_CAN_INVITE_OTHERS: 'guestsCanInviteOthers',
  GUESTS_CAN_SEE_GUESTS: 'guestsCanSeeGuests',
  ORGANIZER: 'organizer',
  IS_ORGANIZER: 'isOrganizer',
  DELETED: 'deleted',
  EVENT_END_TIMEZONE: 'eventEndTimezone',
  CUSTOM_APP_PACKAGE: 'customAppPackage',
  CUSTOM_APP_URI: 'customAppUri',
  UID2445: 'uid2445',
  VERSION: 'version',
  EVENT_UUID: 'event_uuid',
  HWEXT_ALERT_TYPE: 'hwext_alert_type',
  IMPORTANT_EVENT_TYPE: 'important_event_type',
  SYNC_DATA1: 'sync_data1',
  SYNC_DATA2: 'sync_data2',
  SYNC_DATA3: 'sync_data3',
  SYNC_DATA4: 'sync_data4',
  SYNC_DATA5: 'sync_data5',
  SYNC_DATA6: 'sync_data6',
  SYNC_DATA7: 'sync_data7',
  SYNC_DATA8: 'sync_data8',
  SYNC_DATA9: 'sync_data9',
  SYNC_DATA10: 'sync_data10',
  KV_SYNC: 'kv_synced',
  KV_SYNC_TIME: 'kv_sync_time',
  CREATOR: Constants.CREATOR,
  SERVICE: {
    SERVICE_VERIFIED: 'service_verified',              // whether service uri legal, INTEGER
    SERVICE_TYPE: 'service_type',                      // service type of event, TEXT
    SERVICE_CP_BZ_URI: 'service_cp_bz_uri',            // one click service uri passed in by application, TEXT
    SERVICE_CP_MNG_URI: 'service_cp_mng_uri',          // one click service uri for management passed in by application, TEXT
    SERVICE_DESCRIPTION: 'service_description',        // service description of event, TEXT
    SERVICE_MIN_VERSION: 'service_support_min_version' // Minimum version of one click service, INTEGER
  }
}

/**
 * searchable Columns in Events table
 */
export const SEARCH_COLUMNS = [EventColumns.TITLE, EventColumns.DESCRIPTION, EventColumns.EVENT_LOCATION];

export const UPDATE_INSTANCES_COLUMNS = [EventColumns.DTSTART, EventColumns.DTEND, EventColumns.DURATION,
EventColumns.EVENT_TIMEZONE, EventColumns.RRULE, EventColumns.RDATE, EventColumns.EXRULE, EventColumns.EXDATE];