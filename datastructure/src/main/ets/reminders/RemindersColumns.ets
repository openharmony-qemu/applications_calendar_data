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

interface RemindersColumnsType {
  TABLE_NAME: string;
  ID: string;
  EVENT_ID: string;
  MINUTES: string;
  METHOD: string;
  CREATOR: string;
  NOTIFICATION_REMINDER_ID: string;
}

/**
 * the const of table Reminders
 *
 * @since 2022-09-08
 */
export const RemindersColumns: RemindersColumnsType = {
  TABLE_NAME: 'Reminders',
  ID: '_id',
  EVENT_ID: 'event_id',
  MINUTES: 'minutes',
  METHOD: 'method',
  CREATOR: Constants.CREATOR,
  NOTIFICATION_REMINDER_ID: 'notification_reminder_id'
}

export enum MethodType {
  DEFAULT = 0,
  ALERT = 1,
  EMAIL = 2,
  SMS = 3,
  ALARM = 4
}