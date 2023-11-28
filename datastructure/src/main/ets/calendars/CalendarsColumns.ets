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

interface CalendarsColumnsType {
  TABLE_NAME: string;
  ID: string;
  ACCOUNT_NAME: string;
  ACCOUNT_TYPE: string;
  SYNC_ID: string;
  DIRTY: string;
  MUTATORS: string;
  NAME: string;
  CALENDAR_DISPLAY_NAME: string;
  CALENDAR_COLOR: string;
  CALENDAR_COLOR_INDEX: string;
  CALENDAR_ACCESS_LEVEL: string;
  VISIBLE: string;
  SYNC_EVENTS: string;
  CALENDAR_LOCATION: string;
  CALENDAR_TIMEZONE: string;
  OWNER_ACCOUNT: string;
  IS_PRIMARY: string;
  CAN_ORGANIZER_RESPOND: string;
  CAN_MODIFY_TIMEZONE: string;
  CAN_PARTIALLY_UPDATE: string;
  MAX_REMINDERS: string;
  ALLOWED_REMINDERS: string;
  ALLOWED_AVAILABILITY: string;
  ALLOWED_ATTENDEE_TYPES: string;
  DELETED: string;
  CALENDAR_TIME_STAMP: string;
  CAL_SYNC1: string;
  CAL_SYNC2: string;
  CAL_SYNC3: string;
  CAL_SYNC4: string;
  CAL_SYNC5: string;
  CAL_SYNC6: string;
  CAL_SYNC7: string;
  CAL_SYNC8: string;
  CAL_SYNC9: string;
  CAL_SYNC10: string;
  CAN_REMINDER: string;
  CREATOR: string;
}

/**
 * the const of table Calendars
 *
 * @since 2022-09-08
 */
export const CalendarsColumns: CalendarsColumnsType = {
  TABLE_NAME: 'Calendars',
  ID: '_id',
  ACCOUNT_NAME: 'account_name',
  ACCOUNT_TYPE: 'account_type',
  SYNC_ID: '_sync_id',
  DIRTY: 'dirty',
  MUTATORS: 'mutators',
  NAME: 'name',
  CALENDAR_DISPLAY_NAME: 'calendar_displayName',
  CALENDAR_COLOR: 'calendar_color',
  CALENDAR_COLOR_INDEX: 'calendar_color_index',
  CALENDAR_ACCESS_LEVEL: 'calendar_access_level',
  VISIBLE: 'visible',
  SYNC_EVENTS: 'sync_events',
  CALENDAR_LOCATION: 'calendar_location',
  CALENDAR_TIMEZONE: 'calendar_timezone',
  OWNER_ACCOUNT: 'ownerAccount',
  IS_PRIMARY: 'isPrimary',
  CAN_ORGANIZER_RESPOND: 'canOrganizerRespond',
  CAN_MODIFY_TIMEZONE: 'canModifyTimeZone',
  CAN_PARTIALLY_UPDATE: 'canPartiallyUpdate',
  MAX_REMINDERS: 'maxReminders',
  ALLOWED_REMINDERS: 'allowedReminders',
  ALLOWED_AVAILABILITY: 'allowedAvailability',
  ALLOWED_ATTENDEE_TYPES: 'allowedAttendeeTypes',
  DELETED: 'deleted',
  CALENDAR_TIME_STAMP: 'calendar_time_stamp',
  CAL_SYNC1: 'cal_sync1',
  CAL_SYNC2: 'cal_sync2',
  CAL_SYNC3: 'cal_sync3',
  CAL_SYNC4: 'cal_sync4',
  CAL_SYNC5: 'cal_sync5',
  CAL_SYNC6: 'cal_sync6',
  CAL_SYNC7: 'cal_sync7',
  CAL_SYNC8: 'cal_sync8',
  CAL_SYNC9: 'cal_sync9',
  CAL_SYNC10: 'cal_sync10',
  CAN_REMINDER: 'canReminder',
  CREATOR: Constants.CREATOR,
}

interface AppNameType {
  CALENDARDATA: string;
}

export const APP_NAME: AppNameType = {
  CALENDARDATA: 'calendardata',
}

export const DEFAULT_CALENDAR_VALUE: Record<string, number | string> = {
  '_id': 1,
  'account_name': 'phone',
  'account_type': 'local',
  'creator': APP_NAME.CALENDARDATA,
}