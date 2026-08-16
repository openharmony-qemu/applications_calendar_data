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

import { Log } from '@ohos/common';
import { Events } from '@ohos/datastructure/src/main/ets/events/Events';

const TAG: string = 'NormalEventExpand';

/**
 * 普通日程的日期扩展实现
 *
 * @param outDates 承载扩展后日期的数组
 * @param event 扩展哪个日程
 * @param rangeBegin 扩展区间起点
 * @param rangeEnd 扩展区间终点
 */
function expand(outDates: Array<number>, event: Events, rangeBegin: number, rangeEnd: number): void {
  if (!outDates || !event || rangeEnd < rangeBegin) {
    Log.error(TAG, `expand get invalid params`);
    return;
  }

  Log.warn(TAG, `expand normal ${event.id}/${event.creator}`);
  if ((event.dtStart <= rangeEnd) && (event.dtEnd >= rangeBegin)) {
    // 普通日程只有自身一个实例，将dtStart放入dates即可
    outDates.push(event.dtStart);
  }
}

export {
  expand as normalExpand
};