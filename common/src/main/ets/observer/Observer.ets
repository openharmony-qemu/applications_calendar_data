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

import { ObservableMessage } from './Observable';

/**
 * the interface of Observer
 *
 * @since 2022-09-09
 */
export interface Observer {
  /**
   * 观察者被通知后，执行该方法实现行为
   */
  onChange(message?: ObserverMessage);
}

export class ObserverMessage implements ObservableMessage {
}