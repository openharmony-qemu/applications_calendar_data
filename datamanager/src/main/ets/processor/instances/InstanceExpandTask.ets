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

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { ArkTSUtils } from '@kit.ArkTS';
import rdbStore from '@ohos.data.relationalStore';
import { acquireExpandAll } from './InstancesProcessor';
import { common } from '@kit.AbilityKit';
import { reInitGlobalContextInTaskPool } from '@ohos/common';
import CalendarDataHelper from '../../utils/CalendarDataHelper';

export const INSTANCES_EXPAND_TASK_LOCK = 'InstancesExpandTaskLock';

@Concurrent
export async function acquireExpandAllTask(context: common.UIAbilityContext, acquireBegin: number, acquireEnd: number) {
  reInitGlobalContextInTaskPool(context);
  const TAG: string = 'InstancesExpandAsyncTask';
  const rdbStore = await CalendarDataHelper.getInstance().getRdbStore() as rdbStore.RdbStore;
  Log.warn(TAG, `task begin ${acquireBegin}-${acquireEnd}, rdbStore=${rdbStore}`);
  // 创建或获取已有锁
  const asyncLock: ArkTSUtils.locks.AsyncLock = ArkTSUtils.locks.AsyncLock.request('InstancesExpandTaskLock');
  // 获取锁后在回调内执行互斥任务，回调函数结束后锁自动释放
  await asyncLock.lockAsync(async () => {
    await acquireExpandAll(rdbStore, acquireBegin, acquireEnd);
  });
  Log.warn(TAG, `task end ${acquireBegin}-${acquireEnd}`);
}