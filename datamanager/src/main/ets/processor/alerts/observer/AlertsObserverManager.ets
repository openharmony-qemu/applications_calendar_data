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

import data_rdb from '@ohos.data.relationalStore';

import LinkedList from '@ohos.util.LinkedList';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { Observable } from '@ohos/common/src/main/ets/observer/Observable';
import { Observer, ObserverMessage } from '@ohos/common/src/main/ets/observer/Observer';

import { AlertsMessage } from '../AlertsMessage';

const TAG = 'AlertsObserverManager';

/**
 * 通知消息变化可观察者
 *
 * @since 2024-12-05
 */
export class AlertsObserverManager implements Observable {
  private static observableInstance: AlertsObserverManager;
  private mObserverList: LinkedList<Observer> = new LinkedList();


  /**
   * 获取 AlertsObserver 的单例
   */
  public static getInstance() {
    if (!AlertsObserverManager.observableInstance) {
      Log.log(TAG, 'call getInstance init');
      AlertsObserverManager.observableInstance = new AlertsObserverManager();
    }
    return AlertsObserverManager.observableInstance;
  }

  /**
   * 增加一个观察者
   */
  public addObserver(observer: Observer) {
    if (this.mObserverList.length <= 0) {
      this.mObserverList.add(observer);
    }
  }

  /**
   * 删除一个观察者
   */
  public removeObserver(observer: Observer) {
    this.mObserverList.remove(observer);
  }

  /**
   * 被观察者状态发生改变后，通知d订阅的所有观察者更新
   */
  public notifyChanges(message: ObserverMessage) {
    this.mObserverList.forEach((observer) => {
      observer.onChange(message);
    })
  }

  /**
   * 通知提醒变化
   *
   * @param operationName 变化类型
   * @param table 数据变化数据表
   * @param values 变化数据
   */
  public notifyAlertsChanges(operationName: string, table: string,
                             values?: data_rdb.ValuesBucket | data_rdb.ValuesBucket[]) {
    let message = new AlertsMessage();
    message.setOperationName(operationName);
    message.setTableName(table);
    if (values) {
      message.setValues(values);
    }
    this.notifyChanges(message);
  }
}