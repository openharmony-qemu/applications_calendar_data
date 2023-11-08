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

import systemTimer from '@ohos.systemTimer';
import { AsyncCallback } from '@ohos.base';
import { Log } from './Log';

const TAG = 'SystemTimerUtils';

/**
 * 创建一个定时器
 *
 * @param options 定时器选项，数据结构参考系统api：SystemTimer
 * @param callback 定时器的回调函数，到达定时器的触发时间时回调
 */
export async function createTimer(options: systemTimer.TimerOptions, callback?: AsyncCallback<number>): Promise<number | void> {
  let timerId: number | void;
  if (callback !== null && callback !== undefined) {
    timerId = systemTimer.createTimer(options, callback);
  } else {
    timerId = systemTimer.createTimer(options, (err, timerId) => {
      if (err?.message !== undefined) {
        Log.error(TAG, 'failed to create a Timer because:' + err?.message);
      }
      Log.debug(TAG, "A Timer has been created and Timer ID is:" + timerId);
    })
  }
  return timerId;
}

/**
 * 开启一个定时器
 * 系统定时器会去比对 currentTime 与 triggerTime的差值
 * 若差值小于5000ms则设置触发时间 triggerTime 为 currentTime+5000
 * 若差值大于5000ms则正常设置触发时间 triggerTime 为传入的时间
 * 若 currentTime（定时器内部时间）大于 triggerTime，则不会开启定时器
 *
 * @Param timer The timer ID.
 * @Param triggerTime 触发时间
 */
export function startTimer(timer: number, triggerTime: number, callback?: AsyncCallback<void, void>): void {
  if (callback !== null && callback !== undefined) {
    systemTimer.startTimer(timer, triggerTime, callback);
  } else {
    systemTimer.startTimer(timer, triggerTime, (err) => {
      if (err?.message !== undefined) {
        Log.error(TAG, 'failed to startTimer because:' + err?.message);
      }
      Log.debug(TAG, "a Timer start,and this Timer will callback when: " + triggerTime);
    })
  }
}

/**
 * 停止一个定时器
 *
 * @Param timer The timer ID.
 */
export function stopTimer(timer: number, callback?: AsyncCallback<void, void>): void {
  if (callback !== null && callback !== undefined) {
    systemTimer.stopTimer(timer, callback);
  } else {
    systemTimer.stopTimer(timer, (err) => {
      if (err?.message !== undefined) {
        Log.error(TAG, 'failed to stop Timer because:' + err?.message);
      }
      Log.debug(TAG, "a timer has been stopped,and this Timer id is: " + timer);
    })
  }
}

/**
 * 摧毁一个定时器
 *
 * @Param timer The timer ID.
 */
export function destroyTimer(timer: number, callback: AsyncCallback<void, void>): void {
  if (callback !== null && callback !== undefined) {
    systemTimer.destroyTimer(timer, callback);
  } else {
    systemTimer.destroyTimer(timer, (err) => {
      if (err?.message !== undefined) {
        Log.error(TAG, 'failed to destroy Timer' + err?.message);
      }
      Log.debug(TAG, "a timer has been destroyed,and this Timer id is: " + timer);
    })
  }
}