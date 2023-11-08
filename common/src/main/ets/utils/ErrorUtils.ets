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

import { BusinessError } from '@ohos.base';

/**
 * 判断error是否为无错误
 *
 * @param err 错误Error对象
 */
export function hasNoError(err: BusinessError): boolean {
  if (!err) {
    return true;
  }
  return err?.code === 0;
}

/**
 * 判断error是否为有错误
 *
 * @param err 错误Error对象
 */
export function hasError(err: BusinessError): boolean {
  return !hasNoError(err);
}