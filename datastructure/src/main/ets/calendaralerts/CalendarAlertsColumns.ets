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

interface CalendarAlertsColumnsType {
  TABLE_NAME: string;
  ID: string;
  EVENT_ID: string;
  BEGIN: string;
  END: string;
  ALARM_TIME: string;
  CREATION_TIME: string;
  RECEIVED_TIME: string;
  NOTIFY_TIME: string;
  STATE: string;
  MINUTES: string;
  CREATOR: string;
}

/**
 * the const of table CalendarAlerts
 *
 * @since 2022-09-08
 */
export const CalendarAlertsColumns: CalendarAlertsColumnsType = {
  TABLE_NAME: 'CalendarAlerts',
  ID: '_id',
  EVENT_ID: 'event_id',
  BEGIN: 'begin',
  END: 'end',
  ALARM_TIME: 'alarmTime',
  CREATION_TIME: 'creationTime',
  RECEIVED_TIME: 'receivedTime',
  NOTIFY_TIME: 'notifyTime',
  STATE: 'state',
  MINUTES: 'minutes',
  CREATOR: Constants.CREATOR,
}