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

import commonEventManager from '@ohos.commonEventManager';
import { Subscriber } from '@ohos/common/src/main/ets/subscriber/Subscriber'
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { runScheduleNextAlarm } from './AlertsProcessor'
import { CommonEventConstants } from '../../commonevents/CommonEventConstants';
import { BusinessError } from '@ohos.base';

const TAG = 'AlertsSubscriber';

/**
 * the Alerts Subscriber
 *
 * @since 2022-10-08
 */
export class AlertsSubscriber implements Subscriber {
  // AlertsSubscriber 的单例
  private static sInstance: AlertsSubscriber;
  // AlertsSubscriber 持有的订阅者
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  private constructor() {
    this.subscriber;
  }

  /**
   * 获取 AlertsSubscriber 的单例
   */
  public static getInstance() {
    if (!AlertsSubscriber.sInstance) {
      Log.log(TAG, 'call getInstance init');
      AlertsSubscriber.sInstance = new AlertsSubscriber();
    }
    return AlertsSubscriber.sInstance;
  }

  /**
   * 初始化 AlertsSubscriber 持有的 subscriber
   */
  public initSubscriber() {
    if (this.subscriber === null || this.subscriber === undefined) {
      AlertsSubscriber.sInstance.subscribe();
    }
  }

  /**
   * 订阅公共事件
   */
  subscribe() {
    // 订阅的公共事件集合

    // 创建订阅对象
    commonEventManager.createSubscriber(
      { events: [CommonEventConstants.CHECK_NEXT_ALARM, CommonEventConstants.EVENT_REMINDER] }, (err, subscriber) => {
      if (err?.code) {
        Log.error(TAG, `CreateSubscriberCallBack err = ${JSON.stringify(err)}`);
      } else {
        this.subscriber = subscriber;
        Log.info(TAG, "Create subscriber succeed");
        if (this.subscriber != null) {
          Log.info(TAG, "subscriber subscribe commonEvent");
          commonEventManager.subscribe(subscriber, (err, data) => {
            if (err?.code) {
              Log.error(TAG, `SubscribeCallBack err= ${JSON.stringify(err)}`);
            } else {
              Log.info(TAG, `SubscribeCallBack data= ${JSON.stringify(data)}`);
              // 接到广播后，此处会被回调
              runScheduleNextAlarm();
            }
          })
        } else {
          Log.info(TAG, "Need create subscriber");
        }
      }
    })
  }

  /**
   * 取消订阅公共事件
   */
  unSubscribe() {
    if (this.subscriber != null) {
      commonEventManager.unsubscribe(this.subscriber, (err: BusinessError) => {
        if (err?.code) {
          Log.error(TAG, `UnsubscribeCallBack err= = ${JSON.stringify(err)}`);
        } else {
          Log.info(TAG, "Unsubscribe");
          this.subscriber = null;
          Log.info(TAG, "Unsubscribe succeed");
        }
      })
    }
  }
}
