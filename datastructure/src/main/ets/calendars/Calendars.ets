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
 * the structure of table Calendars
 *
 * @since 2022-10-18
 */
export class Calendars {
  id: number;
  accountName: string;
  accountType: string;
  syncId: string;
  dirty: number;
  mutators: string;
  name: string;
  calendarDisplayName: string;
  calendarColor: number;
  calendarColorIndex: string;
  calendarAccessLevel: number;
  visible: number;
  syncEvents: number;
  calendarLocation: string;
  calendarTimezone: string;
  ownerAccount: string;
  isPrimary: number;
  canOrganizerRespond: number;
  canModifyTimeZone: number;
  canPartiallyUpdate: number;
  maxReminders: number;
  allowedReminders: string;
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