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
import { TIME_ZONE_UTC } from '@ohos/common';

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { Events } from '@ohos/datastructure/src/main/ets/events/Events';
import { ExpandFlag } from '../Constants';
import { Recurrence } from '../Recurrence';
import { RecurrenceSet } from '../RecurrenceSet';
import { DateExpandProcessor } from './processor/DateExpandProcessor';
import { LunarRuleExpandProcessor } from './processor/LunarRuleExpandProcessor';


const TAG: string = 'LunarEventExpand';

/**
 * 农历日程的日期扩展实现
 *
 * @param outDates 承载扩展后日期的数组
 * @param event 扩展哪个日程
 * @param rangeBegin 扩展区间起点
 * @param rangeEnd 扩展区间终点
 */
function expand(outDates: Array<number>, event: Events, rangeBegin: number, rangeEnd: number): ExpandFlag {
  const flag: ExpandFlag = new ExpandFlag();
  if (!outDates || !event || (rangeEnd < rangeBegin)) {
    Log.error(TAG, `expand get invalid params`);
    flag.isInvalidParam = true;
    return flag;
  }
  const rruleSet: RecurrenceSet = new RecurrenceSet(event.rRule, event.rDate, event.exRule, event.exDate);
  rruleSet.parseAll();
  Log.warn(TAG, `expand lunar ${event.id}/${event.eventTimeZone}/${event.creator}: ${JSON.stringify(rruleSet)}`);
  const eventTimeZone: string = event.isAllDay() ? TIME_ZONE_UTC : event.eventTimeZone;
  const rxp: LunarRuleExpandProcessor = new LunarRuleExpandProcessor(rangeBegin, rangeEnd, eventTimeZone);
  const dxp: DateExpandProcessor = new DateExpandProcessor(rangeBegin, rangeEnd, eventTimeZone);
  if (rruleSet.hasRecurrence()) {
    let isBreakByRrule: boolean | undefined = undefined;
    rruleSet.rules.forEach((recurrence: Recurrence) => {
      rxp.expand(event.dtStart, recurrence, outDates);
      if (isBreakByRrule === undefined) {
        isBreakByRrule = rxp.isExpandBreakByRule;
      } else {
        // 如果有多个rrule，需要每个rrule都是breakByRule
        isBreakByRrule &&= rxp.isExpandBreakByRule;
      }
    });
    flag.isBreakByRule = isBreakByRrule ?? false;
    rruleSet.dates.forEach((date: string) => {
      dxp.expand(date, outDates);
    });
    rruleSet.exRules.forEach((recurrence: Recurrence) => {
      rxp.exclude(event.dtStart, recurrence, outDates);
    });
    rruleSet.exDates.forEach((date: string) => {
      dxp.exclude(date, outDates);
    });
  } else {
    outDates.push(event.dtStart);
  }
  return flag;
}

export {
  expand as lunarExpand
};