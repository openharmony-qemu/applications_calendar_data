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

/**
 * the const of table Events
 *
 * @since 2022-05-28
 */
export class EventColumns {
  public static TABLE_NAME = 'Events';
  public static ID = '_id';
  public static SYNC_ID = '_sync_id';
  public static DIRTY = 'dirty';
  public static MUTATORS = 'mutators';
  public static EVENT_CALENDAR_TYPE = 'event_calendar_type';
  public static UUID = 'uuid';
  public static EVENT_IMAGE_TYPE = 'event_image_type';
  public static LAST_SYNCED = 'lastSynced';
  public static CALENDAR_ID = 'calendar_id';
  public static TITLE = 'title';
  public static EVENT_LOCATION = 'eventLocation';
  public static LOCATION_LONGITUDE = 'location_longitude';
  public static LOCATION_LATITUDE = 'location_latitude';
  public static DESCRIPTION = 'description';
  public static EVENT_COLOR = 'eventColor';
  public static EVENT_COLOR_INDEX = 'eventColor_index';
  public static EVENT_STATUS = 'eventStatus';
  public static SELF_ATTENDEE_STATUS = 'selfAttendeeStatus';
  public static DTSTART = 'dtstart';
  public static DTEND = 'dtend';
  public static EVENT_TIMEZONE = 'eventTimezone';
  public static DURATION = 'duration';
  public static ALLDAY = 'allDay';
  public static ACCESS_LEVEL = 'accessLevel';
  public static AVAILABILITY = 'availability';
  public static HAS_ALARM = 'hasAlarm';
  public static HAS_EXTENDED_PROPERTIES = 'hasExtendedProperties';
  public static RRULE = 'rrule';
  public static RDATE = 'rdate';
  public static EXRULE = 'exrule';
  public static EXDATE = 'exdate';
  public static ORIGINAL_ID = 'original_id';
  public static ORIGINAL_SYNC_ID = 'original_sync_id';
  public static ORIGINAL_INSTANCE_TIME = 'originalInstanceTime';
  public static ORIGINAL_ALL_DAY = 'originalAllDay';
  public static LAST_DATE = 'lastDate';
  public static EVENT_TIME_STAMP = 'event_time_stamp';
  public static HAS_ATTENDEE_DATE = 'hasAttendeeData';
  public static GUESTS_CAN_MODIFY = 'guestsCanModify';
  public static GUESTS_CAN_INVITE_OTHERS = 'guestsCanInviteOthers';
  public static GUESTS_CAN_SEE_GUESTS = 'guestsCanSeeGuests';
  public static ORGANIZER = 'organizer';
  public static IS_ORGANIZER = 'isOrganizer';
  public static DELETED = 'deleted';
  public static EVENT_END_TIMEZONE = 'eventEndTimezone';
  public static CUSTOM_APP_PACKAGE = 'customAppPackage';
  public static CUSTOM_APP_URI = 'customAppUri';
  public static UID2445 = 'uid2445';
  public static VERSION = 'version';
  public static EVENT_UUID = 'event_uuid';
  public static HWEXT_ALERT_TYPE = 'hwext_alert_type';
  public static IMPORTANT_EVENT_TYPE = 'important_event_type';
  public static SYNC_DATA1 = 'sync_data1';
  public static SYNC_DATA2 = 'sync_data2';
  public static SYNC_DATA3 = 'sync_data3';
  public static SYNC_DATA4 = 'sync_data4';
  public static SYNC_DATA5 = 'sync_data5';
  public static SYNC_DATA6 = 'sync_data6';
  public static SYNC_DATA7 = 'sync_data7';
  public static SYNC_DATA8 = 'sync_data8';
  public static SYNC_DATA9 = 'sync_data9';
  public static SYNC_DATA10 = 'sync_data10';
  public static KV_SYNC = 'kv_synced';
  public static KV_SYNC_TIME = 'kv_sync_time';
  public static CREATOR = Constants.CREATOR;
  public static IDENTIFIER = 'identifier';
  public static SERVICE: serviceType = {
    SERVICE_VERIFIED: 'service_verified', // whether service uri legal, INTEGER
    SERVICE_TYPE:  'service_type', // service type of event, TEXT
    SERVICE_CP_BZ_URI:  'service_cp_bz_uri', // One click service uri passed in by applications, TEXT
    SERVICE_CP_MNG_URI:  'service_cp_mng_uri', // One click service uri for management passed in by applications, TEXT
    SERVICE_DESCRIPTION:  'service_description', // service description of event, TEXT
    SERVICE_MIN_VERSION:  'service_support_min_version' // Minimum version of one click service, INTEGER
  }
}

/**
 * searchable Columns in Events table
 */
export const SEARCH_COLUMNS = [EventColumns.TITLE, EventColumns.DESCRIPTION, EventColumns.EVENT_LOCATION];

export const UPDATE_INSTANCES_COLUMNS = [EventColumns.DTSTART, EventColumns.DTEND, EventColumns.DURATION,
EventColumns.EVENT_TIMEZONE, EventColumns.RRULE, EventColumns.RDATE, EventColumns.EXRULE, EventColumns.EXDATE];