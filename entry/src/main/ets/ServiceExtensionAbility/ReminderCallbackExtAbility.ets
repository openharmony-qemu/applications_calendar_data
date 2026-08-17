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

import { ServiceExtensionAbility, Want } from '@kit.AbilityKit';
import { HashMap } from '@kit.ArkTS';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { CommonInnerEvent, Log } from '@ohos/common';
import { AlertsObserverManager, AlertsObserver, AlertsOperationName } from '@ohos/datamanager';
import { RemindersColumns } from '@ohos/datastructure';

const TAG: string = 'ReminderCallbackExtAbility';

const REQUEST_RUNNING_TIME_OUT: number = 60 * 1000;

/**
 * 自定义提醒、农历提醒，提醒代理无法处理，使用回拉机制。
 * 设置提醒代理时，设置rruleWantAgent参数，参数中设置的WantAgent对应此ServiceExtension，
 * 提醒代理触发时会同时保障回拉此Service，日历收到Service回拉后计算并设定下一次提醒的时间点。
 */
export default class ReminderCallbackExtAbility extends ServiceExtensionAbility {
  // 记录每一个onRequest任务的执行状态，true表示任务正在执行，false表示执行完毕，所有request执行完成后，结束服务
  private requestRunningState: HashMap<number, boolean> = new HashMap();
  private timeoutIdMap: HashMap<number, number> = new HashMap();

  onCreate(want: Want): void {
    super.onCreate(want);
    Log.info(TAG, 'onCreate');
  }

  onDestroy(): void {
    super.onDestroy();
    Log.info(TAG, 'onDestroy');
  }

  onRequest(want: Want, startId: number): void {
    super.onRequest(want, startId);
    Log.info(TAG, `onRequest: ${startId}`);
    this.onRequestStart(startId);
    AlertsObserverManager.getInstance().addObserver(AlertsObserver.getInstance());

    const type: number = typeof want.parameters?.CallbackType === 'number' ? want.parameters.CallbackType : 0;
    Log.info(TAG, `onRequest CallbackType:${type}`);
    if (type !== undefined && type !== null) {
      AlertsObserverManager.getInstance().notifyAlertsChanges(AlertsOperationName.INSERT, RemindersColumns.TABLE_NAME);
    }
    emitter.once({ eventId: CommonInnerEvent.REMIND_CALC_END }, () => {
      Log.log(TAG, 'remind calc end');
      this.terminateSelfByStartId(startId);
    });
  }


  private onRequestStart(requestId: number): void {
    this.requestRunningState.set(requestId, true);
    const timeoutId: number = setTimeout(() => {
      Log.warn(TAG, `execute requestId ${requestId} timeout.`);
      this.requestRunningState.set(requestId, false);
      this.checkAndTerminateSelf();
    }, REQUEST_RUNNING_TIME_OUT);
    this.timeoutIdMap.set(requestId, timeoutId);
  }

  private terminateSelfByStartId(requestId: number): void {
    this.requestRunningState.set(requestId, false);
    if (this.timeoutIdMap.hasKey(requestId)) {
      clearTimeout(this.timeoutIdMap.get(requestId));
    }
    this.checkAndTerminateSelf();
  }

  private checkAndTerminateSelf(): void {
    if (this.requestRunningState.length === 0) {
      this.terminateSelf();
      return;
    }
    let hasRequestRunning: boolean = false;
    this.requestRunningState.forEach((value: boolean, key: number) => {
      hasRequestRunning = hasRequestRunning || value;
    });
    if (!hasRequestRunning) {
      this.terminateSelf();
    }
  }

  private terminateSelf(): void {
    Log.info(TAG, 'terminateSelf called.');
    this.context.terminateSelf().then(() => {
      Log.info(TAG, 'Succeeded in terminating self.');
    }).catch((err: BusinessError) => {
      Log.error(TAG, `Failed to terminate self. Code is ${err.code}, message is ${err.message}`);
    });
  }
}