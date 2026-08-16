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

import reminderAgentManager from '@ohos.reminderAgentManager';
import { Log } from '@ohos/common';
import { Events } from '@ohos/datastructure/src/main/ets/events/Events';
import { RecurrenceSet } from '../RecurrenceSet';
import { adaptLunarReminder } from './adapter/LunarAdapter';
import { adaptRecurrenceReminder } from './adapter/RecurrenceAdapter';

const TAG: string = 'ReminderAgentAdapter';

function adaptReminderRequest(reminderRequest: reminderAgentManager.ReminderRequestCalendar, event: Events) {
  if (!reminderRequest) {
    Log.warn(TAG, `adaptReminderRequest with invalid request`);
    return;
  }
  if (!event) {
    Log.warn(TAG, `adaptReminderRequest with invalid event`);
    return;
  }

  const rruleSet: RecurrenceSet = new RecurrenceSet(event.rRule, event.rDate, event.exRule, event.exDate);
  if (event.isLunarEvent()) {
    adaptLunarReminder(reminderRequest, event);
  } else if (rruleSet.hasRecurrence()) {
    adaptRecurrenceReminder(reminderRequest, event);
  }
}

export {
  adaptReminderRequest
}