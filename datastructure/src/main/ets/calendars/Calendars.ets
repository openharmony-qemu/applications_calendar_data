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
  public id: number = 0;
  public uuid: string = '';
  public accountName: string = '';
  public accountType: string = '';
  public syncId: string = '';
  public dirty: number = 0;
  public mutators: string = '';
  public name: string = '';
  public calendarDisplayName: string = '';
  public calendarColor: number = 0;
  public calendarColorIndex: string = '';
  public calendarAccessLevel: number = 0;
  public visible: number = 0;
  public syncEvents: number = 0;
  public calendarLocation: string = '';
  public calendarTimezone: string = '';
  public ownerAccount: string = '';
  public isPrimary: number = 0;
  public canOrganizerRespond: number = 0;
  public canModifyTimeZone: number = 0;
  public canPartiallyUpdate: number = 0;
  public maxReminders: number = 0;
  public allowedReminders: string = '';
  public allowedAvailability: string = '';
  public allowedAttendeeTypes: string = '';
  public deleted: number = 0;
  public calendarTimeStamp: number = 0;
  public calSync1: string = '';
  public calSync2: string = '';
  public calSync3: string = '';
  public calSync4: string = '';
  public calSync5: string = '';
  public calSync6: string = '';
  public calSync7: string = '';
  public calSync8: string = '';
  public calSync9: string = '';
  public calSync10: string = '';
  public canReminder: number = 1;
  public creator: string = '';
}