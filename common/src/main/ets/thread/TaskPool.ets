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

import process from '@ohos.process';
import common from '@ohos.app.ability.common';
import { GlobalThis } from '../utils/GlobalThis';

export function isMainThread(): boolean {
  return process.pid === process.tid;
}

/**
 * 在TaskPool线程中重新初始化GlobalThis上下文
 * @param context
 */
export function reInitGlobalContextInTaskPool(context: common.UIAbilityContext) {
  if (!isMainThread()) {
    // 切线程后GlobalThis失效，是一个全新对象，需要赋予context，否则后续创建dsHelper会失败，导致无法查询数据库
    GlobalThis.getSingleInstance().appContext = context;
  }
}