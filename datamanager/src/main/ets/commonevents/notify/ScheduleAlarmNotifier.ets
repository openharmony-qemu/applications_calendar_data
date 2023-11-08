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

import { sendBroadcast } from '@ohos/common/src/main/ets/broadcast/BroadcastHelper';
import { CommonEventConstants } from '../CommonEventConstants';
import { runScheduleNextAlarm } from '../../processor/alerts/AlertsProcessor';

/**
 * 在需要提醒的时间发送 Event_Reminder 广播通知，如果提醒时间小于当前时间，则返回false
 *
 * @param nextAlarmTime 提醒的时间
 * @return 提醒时间是否小于当前时间
 */
export async function notifyEventReminder(nextAlarmTime: number): Promise<boolean> {
  // 设置定时器发送 EVENT_REMINDER 广播
  let currentMillis = new Date().getTime();
  if (nextAlarmTime < currentMillis) {
    return false;
  }
  setTimeout(() => {
    sendBroadcast(CommonEventConstants.EVENT_REMINDER);
    runScheduleNextAlarm();
  }, nextAlarmTime - currentMillis);
  return true;
}