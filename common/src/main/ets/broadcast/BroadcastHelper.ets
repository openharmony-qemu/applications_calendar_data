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
import { Log } from '../utils/Log';
import { BusinessError } from '@ohos.base';

const TAG = 'BroadcastHelper';

/**
 * 发送广播
 *
 * @param action 广播action
 * @param data 广播携带数据，数据结构参考系统api：CommonEventPublishData
 */
export function sendBroadcast(action: string, data?: commonEventManager.CommonEventPublishData): void {
  const callback = (err: BusinessError): void => {
    if (err?.code) {
      Log.error(TAG, `sendBroadcast [${action}] get err:${err?.code}, msg=${err?.message}`);
    } else {
      Log.info(TAG, `sendBroadcast [${action}] successful`);
    }
  };
  if (data) {
    commonEventManager.publish(action, data, callback);
  } else {
    commonEventManager.publish(action, callback);
  }
}