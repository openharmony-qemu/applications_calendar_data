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

import { Observer } from './Observer';

/**
 * the interface of Observable
 *
 * @since 2022-09-09
 */
export interface Observable {
  /**
   * 增加一个观察者
   */
  addObserver(observer: Observer);

  /**
   * 删除一个观察者
   */
  removeObserver(observer: Observer);

  /**
   * 被观察者状态发生改变后，通知订阅的所有观察者更新
   */
  notifyChanges(message?: ObservableMessage);
}

export interface ObservableMessage {}