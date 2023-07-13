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

/**
 * the structure of table Events
 *
 * @since 2022-05-28
 */
export class Events {
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

  constructor() {
  }

  /**
   * 判断是否全天日程
   *
   * @return true 全天日程 false 非全天日程
   */
  public isAllDay(): boolean {
    return this.allDay != 0;
  }
}