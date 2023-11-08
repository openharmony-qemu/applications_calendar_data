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

interface CalendarsType {
  id: number
  accountName: string
  accountType: string
  syncId: string
  dirty: number
  mutators: string
  name: string
  calendarDisplayName: string
  calendarColor: number
  calendarColorIndex: string
  calendarAccessLevel: number
  visible: number
  syncEvents: number
  calendarLocation: string
  calendarTimezone: string
  ownerAccount: string
  isPrimary: number
  canOrganizerRespond: number
  canModifyTimeZone: number
  canPartiallyUpdate: number
  maxReminders: number
  allowedReminders: string
  allowedAvailability: string;
  allowedAttendeeTypes: string;
  deleted: number;
  calendarTimeStamp: number;
  calSync1: string;
  calSync2: string;
  calSync3: string;
  calSync4: string;
  calSync5: string;
  calSync6: string;
  calSync7: string;
  calSync8: string;
  calSync9: string;
  calSync10: string;
  canReminder: number;
  creator: string;
}

/**
 * the structure of table Calendars
 *
 * @since 2022-10-18
 */
export class Calendars implements CalendarsType {
  id = 0;
  accountName = '';
  accountType = '';
  syncId = '';
  dirty = 0;
  mutators = '';
  name = '';
  calendarDisplayName = '';
  calendarColor = 0;
  calendarColorIndex = '';
  calendarAccessLevel = 0;
  visible = 0;
  syncEvents = 0;
  calendarLocation = '';
  calendarTimezone = '';
  ownerAccount = '';
  isPrimary = 0;
  canOrganizerRespond = 0;
  canModifyTimeZone = 0;
  canPartiallyUpdate = 0;
  maxReminders = 0;
  allowedReminders = '';
  allowedAvailability = '';
  allowedAttendeeTypes = '';
  deleted = 0;
  calendarTimeStamp = 0;
  calSync1 = '';
  calSync2 = '';
  calSync3 = '';
  calSync4 = '';
  calSync5 = '';
  calSync6 = '';
  calSync7 = '';
  calSync8 = '';
  calSync9 = '';
  calSync10 = '';
  canReminder = 0;
  creator = '';
}