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

import { Observer } from '@ohos/common/src/main/ets/observer/Observer';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import data_rdb from '@ohos.data.relationalStore';
import { AlertsMessage } from '../AlertsMessage';
import { AlertsTask } from '../AlertsTask';
import judgerFactory from '../judger/AlertsUpdateJudgerFactory';

const TAG = 'AlertsObserver';

/**
 * the Alerts Observer
 *
 * @since 2024-12-09
 */
export class AlertsObserver implements Observer {
  private static sInstance: AlertsObserver;
  private isAlertTimerBeingCreated: boolean;
  private mLastUpdateAlertTime: number;
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
   * 获取 AlertsObserver 的单例
   */
  public static getInstance() {
    if (!AlertsObserver.sInstance) {
      Log.log(TAG, 'call getInstance init');
      AlertsObserver.sInstance = new AlertsObserver();
    }
    return AlertsObserver.sInstance;
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

  public onChange(message: AlertsMessage) {
    Log.info(TAG, 'AlertsObserver enter');
    if (isNeedToUpdateAlerts(message)) {
      Log.info(TAG, 'AlertsObserver:Alarm is needed to update.');
      AlertsTask.instance().startAlarmTask();
    }
    Log.info(TAG, 'AlertsObserver leave');
  }
}

/**
 * 判断是否需要更新 Alerts 表
 *
 * @Param message 对数据表进行操作的信息
 * @Return 是否需要更新 Alerts 表
 */
export function isNeedToUpdateAlerts(message: AlertsMessage): boolean {
  if (message === null || message === undefined) {
    return false;
  }

  let operationName: string = message.getOperationName();
  let tableName: string = message.getTableName();
  let values: data_rdb.ValuesBucket | data_rdb.ValuesBucket[] = message.getValues();

  const alarmNeedUpdateJudger = judgerFactory.getAlertsUpdateJudger(operationName);
  if (alarmNeedUpdateJudger) {
    return alarmNeedUpdateJudger.isNeedToUpdateAlerts(tableName, values);
  }
  Log.warn(TAG, 'AlarmNeedUpdateJudger:get failed!');
  return false;

}