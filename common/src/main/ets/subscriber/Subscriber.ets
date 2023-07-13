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

/**
 * Subscriber 的接口，接收 commonEvents 的类，需要归一实现该接口
 *
 * @since 2022-10-08
 */
export interface Subscriber {
  /**
   * 订阅公共事件
   */
  subscribe();

  /**
   * 取消订阅公共事件
   */
  unSubscribe();
}