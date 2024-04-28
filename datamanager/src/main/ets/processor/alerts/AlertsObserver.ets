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

import data_rdb from '@ohos.data.relationalStore';
import { Observer } from '@ohos/common/src/main/ets/observer/Observer';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { startTimer, stopTimer } from '@ohos/common/src/main/ets/utils/SystemTimerUtils';
import { AlertsMessage } from './AlertsMessage';
import AlertsUpdateJudgerFactory from './AlertsUpdateJudgerFactory';
import { runScheduleNextAlarm } from './AlertsProcessor';

const TAG = 'AlertsObserver';

export const INSERT_OPERATION_NAME = 'insert';
export const UPDATE_OPERATION_NAME = 'update';
export const DELETE_OPERATION_NAME = 'delete';
export const WAITING_DELAY_TIME = 5000;

/**
 * the Alerts Observer
 *
 * @since 2022-09-09
 */
export class AlertsObserver implements Observer {
  // AlertsObserver的单例
  private static sInstance: AlertsObserver;

  // 用于判断 checkNextAlarm 是否正在创建定时器，防止短时间内多个进程同时访问 checkNextAlarm 方法并创建多个定时器
  private isAlertTimerBeingCreated: boolean;

  // 记录上一次需要执行刷新操作的时刻
  private mLastUpdateAlertTime: number;

  // 记录上一次定时器的ID
  private mAlertTimerId: number;

  /**
   * 初始化变量
   */
  private constructor() {
    this.isAlertTimerBeingCreated = false;
    this.mLastUpdateAlertTime = 0;
    this.mAlertTimerId = 0;
  }

  /**
   * 返回 创建线程方法屏蔽标志位，防止两次过近的调用创建多个定时器
   */
  public getIsAlertTimerBeingCreated(): boolean {
    return this.isAlertTimerBeingCreated;
  }

  /**
   * 设置 创建线程方法屏蔽标志位，防止两次过近的调用创建多个定时器
   */
  public setIsAlertTimerBeingCreated(isAlertTimerBeingCreated: boolean) {
    this.isAlertTimerBeingCreated = isAlertTimerBeingCreated;
  }

  /**
   * 返回上一次需要执行刷新操作的时刻
   */
  public getLastUpdateAlertTime(): number {
    return this.mLastUpdateAlertTime;
  }

  /**
   * 返回上一次定时器的ID
   */
  public getAlertTimerId(): number {
    return this.mAlertTimerId;
  }

  /**
   * 返回上一次需要执行刷新操作的时刻
   */
  public setLastUpdateAlertTime(lastUpdateAlertTime: number) {
    this.mLastUpdateAlertTime = lastUpdateAlertTime;
  }

  /**
   * 返回上一次定时器的ID
   */
  public setAlertTimerId(alertTimerId: number) {
    this.mAlertTimerId = alertTimerId;
  }

  /**
   * 获取 AlertsObserver 的单例
   */
  public static getInstance() {
    if (!AlertsObserver.sInstance) {
      Log.log(TAG, 'call getInstance init');
      AlertsObserver.sInstance = new AlertsObserver();
    }
    return AlertsObserver.sInstance;
  }

  onChange(message: AlertsMessage) {
    Log.debug(TAG, "AlertsObserver enter");

    // 判断是否需要更新Alarm
    if (isNeedToUpdateAlerts(message)) {
      Log.debug(TAG, "AlertsObserver:Alarm is needed to update.");
      checkNextAlarm();
    }
    Log.debug(TAG, "AlertsObserver leave");
  }
}

/**
 * 判断是否需要更新 Alerts 表
 *
 * @Param message 对数据表进行操作的信息
 * @Return 是否需要更新 Alerts 表
 */
function isNeedToUpdateAlerts(message: AlertsMessage): boolean {
  // 通过message[operationName,[table,values,predicates]]判断增改删方法对不同表的字段操作判断是否需要刷新
  if (message === null || message === undefined) {
    return false;
  }

  // 传入的参数为操作名称和具体操作细节
  let operationName: string = message.getOperationName();
  let tableName: string = message.getTableName();
  let values: data_rdb.ValuesBucket | data_rdb.ValuesBucket[] = message.getValues();

  // 策略模式+工厂模式:根据operationName使用不同的判断逻辑生产不同实例,扩展不同场景只需要额外增加多的AlarmNeedUpdateJudger类即可
  let alarmNeedUpdateJudgerFactory = new AlertsUpdateJudgerFactory();
  let AlarmNeedUpdateJudger = alarmNeedUpdateJudgerFactory.getAlertsUpdateJudger(operationName);
  if (AlarmNeedUpdateJudger !== null && AlarmNeedUpdateJudger != undefined) {
    return AlarmNeedUpdateJudger.isNeedToUpdateAlerts(tableName, values);
  }
  Log.error(TAG, "AlarmNeedUpdateJudger:get Null, You need to confirm your operationName！");
  return false;
}

/**
 *  检查下一个 alarm 的时间 并在恰当的时间进行 Alerts 表的更新
 */
export function checkNextAlarm() {
  Log.debug(TAG, "checkNextAlarm enter");
  let alertsObserver = AlertsObserver.getInstance();
  createAndStartTimerAfterFiveSeconds(alertsObserver);
  Log.debug(TAG, "checkNextAlarm end");
  return;
}

/**
 * 停止上一个定时器并重置该定时器，该定时器会在5s后到期
 *
 * @Param alertsObserver 表示 AlertsObserver 的实例
 */
function stopLastTimerAndStartThisTimer(alertsObserver: AlertsObserver) {
  let alertTimerId = alertsObserver.getAlertTimerId();
  Log.debug(TAG, `Clear Last AlertTimer, and AlertTimerId is` + JSON.stringify(alertTimerId));
  stopTimer(alertTimerId, (err) => {
    if (err?.message !== undefined) {
      Log.error(TAG, 'failed to stopTimer' + err?.message);
    }
    Log.debug(TAG, 'system.stopTimer successful' + err?.message);
    startTimerAfterFiveSeconds(alertsObserver, alertTimerId);
  })
  Log.debug(TAG, `Success to reStart Last AlertTimer, and alertTimerId is ` + JSON.stringify(alertTimerId));
}

/**
 * 创建并开启一个定时器，该定时器会在5s后到期
 *
 * @Param alertsObserver 表示 AlertsObserver 的实例
 */
async function createAndStartTimerAfterFiveSeconds(alertsObserver: AlertsObserver) {
  Log.debug(TAG, `create Timer begin`);

  // 设置5s后的定时器，并发送 CHECK_NEXT_ALARM 广播
  alertsObserver.setIsAlertTimerBeingCreated(false);
  setTimeout(() => {
    runScheduleNextAlarm();
  }, 5000);
  Log.debug(TAG, `create Timer end`);
}

/**
 * 开启一个定时器，并记录定时器ID和触发时间到 AlertsObserver 中去，该定时器会在5s后到期
 *
 * @Param alertsObserver 表示 AlertsObserver 的实例
 */
function startTimerAfterFiveSeconds(alertsObserver: AlertsObserver, timerId: number) {
  Log.debug(TAG, `start Timer begin`);
  Log.debug(TAG, "A Timer has been created and Timer ID is:" + timerId);
  let currentTime = new Date().getTime();
  let triggerTime = currentTime + WAITING_DELAY_TIME;
  Log.debug(TAG, "timer start begin,and Timer will callback when: " + triggerTime);
  startTimer(timerId, triggerTime, (err) => {
    if (err !== undefined && err !== null) {
      if (err?.message !== undefined && err?.message !== null) {
        Log.error(TAG, 'failed to startTimer' + err?.message);
      }
    }
    Log.debug(TAG, "timer start end,and Timer will callback when: " + triggerTime);
  })

  // 记录新定时器的timerId
  alertsObserver.setAlertTimerId(timerId);
  Log.debug(TAG, `start Timer end`);
}