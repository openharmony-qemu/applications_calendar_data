/**
 * @file Describe the file
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { Log } from '@ohos/common/src/main/ets/utils/Log';

import { HashMap } from '@kit.ArkTS';
import { AlertsMessageProcessor } from './AlertsMessageProcessor';

const TAG = 'AlertsObserver';

export const WAITING_DELAY_TIME = 1000;

/**
 * 通知消息任务
 *
 * @since 2024-12-11
 */
export class AlertsTask {
  private static _instance: AlertsTask = new AlertsTask();
  private runningMap: HashMap<string, number> = new HashMap();

  static instance(): AlertsTask {
    return AlertsTask._instance;
  }

  reset() {
    this.runningMap.clear();
  }

  /**
   *  创建并开启一个定时器, 检查下一个 alarm 的时间, 并在恰当的时间进行 Alerts 表的更新
   */
  public async startAlarmTask() {
    Log.info(TAG, 'checkNextAlarm enter');
    this.debounce(TAG, () => {
      AlertsMessageProcessor.runScheduleNextAlarm();
    }, WAITING_DELAY_TIME);
    Log.info(TAG, 'checkNextAlarm end');
  }

  /**
   * 防抖,将执行放在delay时间后触发,delay时间内再次执行则取消之前的执行重新设置delay时间后触发最新的执行
   *
   * @param func 要限制调用的方法
   * @param delay 防抖间隔时间
   */
  private debounce(tag: string, task: Function, delay: number): void {
    if (this.runningMap.get(tag)) {
      clearTimeout(this.runningMap.get(tag));
      this.runningMap.remove(tag);
    }
    const timerId = setTimeout((): void => {
      clearTimeout(this.runningMap.get(tag));
      this.runningMap.remove(tag);
      task();
    }, delay);
    this.runningMap.set(tag, timerId);
  }
}