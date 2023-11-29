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

interface EventsType {
  id: number;
  syncId: string;
  dirty: number;
  mutators: string;
  calendarType: number;
  imageType: string;
  lastSynced: number;
  calendarId: number;
  title: string;
  eventLocation: string;
  longitude: string;
  latitude: string;
  description: string;
  eventColor: number;
  eventColorIndex: string;
  eventStatus: number;
  selfAttendeeStatus: number;
  dtStart: number;
  dtEnd: number;
  eventTimeZone: string;
  duration: string;
  allDay: number;
  accessLevel: number;
  availability: number;
  hasAlarm: number;
  hasExtendedProperties: number;
  rRule: string;
  rDate: string;
  exRule: string;
  exDate: string;
  originalId: number;
  originalSyncId: string;
  originalInstanceTime: number;
  originalAllDay: number;
  lastDate: number;
  eventTimeStamp: number;
  hasAttendeeData: number;
  guestsCanModify: number;
  guestsCanInviteOthers: number;
  guestsCanSeeGuests: number;
  organizer: string;
  isOrganizer: number;
  deleted: number;
  eventEndTimezone: string;
  customAppPackage: string;
  customAppUri: string;
  uid2445: string;
  version: number;
  eventUuid: string;
  hwExtAlertType: number;
  importantEventType: number;
  // event service
  serviceVerified: number;
  serviceType: string;
  serviceCpBzUri: string;
  serviceCpMngUri: string;
  serviceDescription: string;
  serviceSupportMinVersion: number;
  // birthdayKind
  syncData1: string;
  syncData2: string;
  syncData3: string;
  syncData4: string;
  syncData5: string;
  syncData6: string;
  syncData7: string;
  syncData8: string;
  syncData9: string;
  syncData10: string;
  kvSynced: number;
  kvSyncTime: number;
  creator: string;
}

/**
 * the structure of table Events
 *
 * @since 2022-05-28
 */
export class Events implements EventsType {
  id = 0;
  syncId = '';
  dirty = 0;
  mutators = '';
  calendarType = 0;
  imageType = '';
  lastSynced = 0;
  calendarId = 0;
  title = '';
  eventLocation = '';
  longitude = '';
  latitude = '';
  description = '';
  eventColor = 0;
  eventColorIndex = '';
  eventStatus = 0;
  selfAttendeeStatus = 0;
  dtStart = 0;
  dtEnd = 0;
  eventTimeZone = '';
  duration = '';
  allDay = 0;
  accessLevel = 0;
  availability = 0;
  hasAlarm = 0;
  hasExtendedProperties = 0;
  rRule = '';
  rDate = '';
  exRule = '';
  exDate = '';
  originalId = 0;
  originalSyncId = '';
  originalInstanceTime = 0;
  originalAllDay = 0;
  lastDate = 0;
  eventTimeStamp = 0;
  hasAttendeeData = 0;
  guestsCanModify = 0;
  guestsCanInviteOthers = 0;
  guestsCanSeeGuests = 0;
  organizer = '';
  isOrganizer = 0;
  deleted = 0;
  eventEndTimezone = '';
  customAppPackage = '';
  customAppUri = '';
  uid2445 = '';
  version = 0;
  eventUuid = '';
  hwExtAlertType = 0;
  importantEventType = 0;
  // event service
  serviceVerified = 0;
  serviceType = '';
  serviceCpBzUri = '';
  serviceCpMngUri = '';
  serviceDescription = '';
  serviceSupportMinVersion = 0;
  // birthdayKind
  syncData1 = '';
  syncData2 = '';
  syncData3 = '';
  syncData4 = '';
  syncData5 = '';
  syncData6 = '';
  syncData7 = '';
  syncData8 = '';
  syncData9 = '';
  syncData10 = '';
  kvSynced = 0;
  kvSyncTime = 0;
  creator = '';

  /**
   * 判断是否全天日程
   *
   * @return true 全天日程 false 非全天日程
   */
  public isAllDay(): boolean {
    return this.allDay === 1;
  }
}