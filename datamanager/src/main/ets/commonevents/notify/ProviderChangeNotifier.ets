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

import { CommonEventConstants } from '../CommonEventConstants';
import { sendBroadcast } from '@ohos/common/src/main/ets/broadcast/BroadcastHelper';

export const OPERATION_INSERT: string = 'insert';

export const OPERATION_UPDATE: string = 'update';

export const OPERATION_DELETE: string = 'delete';

export const OPERATION_UNKNOWN: string = 'unknown';

const BROAD_CAST_DELAY: number = 100;

/**
 * 发送数据库变化广播通知
 *
 * @param tableName 变化的表
 * @param operation 操作：插入、更新、删除、未知
 */
interface ParametersI {
  table: string;
  operation: string;
}

interface DataI {
  parameters: ParametersI;
}

export function notifyProviderChange(tableName: string, operation: string) {
  const data: DataI = {
    parameters: {
      table: tableName,
      operation: operation,
    }
  };
  setTimeout(() => {
    sendBroadcast(CommonEventConstants.DATA_CHANGED, data);
  }, BROAD_CAST_DELAY);
}