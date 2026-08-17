/**
 * @file Describe the file
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import { CustomTime, Log, TIME_ZONE_UTC } from '@ohos/common';
import { getMaxDayInMonth } from '@ohos/common/src/main/ets/utils/TimeUtils';
import { Frequency } from '../../Constants';
import { Recurrence } from '../../Recurrence';

const TAG: string = 'DaySet';

// 月底最小值为平年2月的28天
const MIN_END_OF_MONTH: number = 28;

/**
 * 标记一个月内那些天被选中的集合，用于循环日程扩展时使用
 */
export class DaySet {
  public rule: Recurrence | null = null;
  private year: number = 0;
  private month: number = 0;
  private daySet: Record<number, boolean> = {};
  private mCustomTime: CustomTime = new CustomTime();

  constructor() {
    this.mCustomTime.setTimeZone(TIME_ZONE_UTC);
  }

  /**
   * 判断daySet中是否包含某一天
   *
   * @param year 年份，最小1970
   * @param month 月份，支持0-11,0表示1月，11表示12月
   * @param day 日期
   * @returns
   */
  public contains(year: number, month: number, day: number): boolean {
    if ((year < 1970) || (month < 0 || month > 11)) {
      Log.warn(TAG, `contains get invalid year or month ${year} ${month}`);
      return false;
    }
    if (day < 1 || day > MIN_END_OF_MONTH) {
      this.mCustomTime.setSafety(year, month, day);
      return this.isContainsDay(this.mCustomTime.getYear(), this.mCustomTime.getMonth(), this.mCustomTime.getDate());
    }
    return this.isContainsDay(year, month, day);
  }

  private isContainsDay(year: number, month: number, day: number): boolean {
    if ((this.year != year) || (this.month != month)) {
      const maxDayInMonth: number = getMaxDayInMonth(year, month + 1);
      if ((day < 1) || (day > maxDayInMonth)) {
        Log.warn(TAG, `contains get invalid day ${day}`);
        return false;
      }
      this.mCustomTime.set(year, month, day);
      this.year = year;
      this.month = month;
      if (!this.rule) {
        return false;
      }
      this.initDaySet(this.mCustomTime, this.rule, maxDayInMonth);
    }
    return this.containsDay(day);
  }

  private initDaySet(generated: CustomTime, rule: Recurrence, maxDayInMonth: number) {
    // 重置daySet
    this.resetDaySet();

    // 按周几的配置初始化daySet
    this.initDaySetByWeekDays(generated, rule, maxDayInMonth);

    // 按几号的配置初始化daySet
    this.initDaySetByMonthDays(rule, maxDayInMonth);
    Log.info(TAG, `initDaySet ${this.year} ${this.month}`);
  }

  private resetDaySet() {
    this.daySet = {};
  }

  private initDaySetByWeekDays(generated: CustomTime, rule: Recurrence, lastDayInMonth: number) {
    const byDayRuleCount = rule.byWeekDayCount();
    if (byDayRuleCount <= 0) {
      return;
    }
    // 计算本月第一天是周几
    let weekOfFirstDay: number = 0;
    let day: number = generated.getDate();
    while (day >= 8) {
      day -= 7;
    }
    weekOfFirstDay = generated.getDayOfWeek();
    if (weekOfFirstDay >= day) {
      weekOfFirstDay = weekOfFirstDay - day + 1;
    } else {
      weekOfFirstDay = weekOfFirstDay - day + 8;
    }

    // 根据rule的byWeekDay规则进行遍历计算
    for (let index: number = 0; index < byDayRuleCount; index++) {
      // 根据byWeekDay规则和本月第一天是周几，计算出规则所属的本月日期
      day = rule.byWeekDay[index] - weekOfFirstDay + 1;
      if (day <= 0) {
        day += 7;
      }

      // 如果有weekNum设置，则取weekNum计算，如果没有该设置则按每周都循环来计算
      const weekNum: number = rule.getWeekNum(index);
      if (weekNum == 0) {
        // weekNum为0表示无周数设置，每周都循环
        for (; day <= lastDayInMonth; day += 7) {
          this.addDay(day);
        }
      } else if (weekNum > 0) {
        // weekNum为正数，取weekNum对应的day，但不能超过本月最后一天
        day += 7 * (weekNum - 1);
        if (day <= lastDayInMonth) {
          this.addDay(day);
        }
      } else {
        // weekNum为负数，则从本月的最后一个星期倒着计算，但不能小于本月第一天
        for (; day <= lastDayInMonth; day += 7) {
        }
        day += 7 * weekNum;
        if (day >= 1) {
          this.addDay(day);
        }
      }
    }
  }

  private initDaySetByMonthDays(rule: Recurrence, lastDayInMonth: number) {
    if (rule.freq <= Frequency.WEEKLY) {
      return;
    }
    const byMonthDayCount: number = rule.byMonthDayCount();
    if (byMonthDayCount <= 0) {
      return;
    }
    let day: number = 0;
    const byWeekDayCount: number = rule.byWeekDayCount();
    if (byWeekDayCount == 0) {
      // 没有按周几循环的规则，直接按几号的规则计算
      for (let index = 0; index < byMonthDayCount; index++) {
        day = rule.byMonthDay[index];
        if (day > 0) {
          this.addDay(day);
        } else {
          day = lastDayInMonth + day + 1;
          if (day >= 1 && day <= lastDayInMonth) {
            this.addDay(day);
          }
        }
      }
      return;
    }

    // 如果有按几号的规则，优先几号的规则，忽视周几的规则
    for (day = 1; day <= lastDayInMonth; day++) {
      next_day: {
        if (this.containsDay(day)) {
          for (let index = 0; index < byMonthDayCount; index++) {
            if (rule.byMonthDay[index] == day) {
              // 同时满足周几和几号的规则，保留
              break next_day;
            }
          }

          // 符合周几的规则，但不符合几号的规则，移除
          this.removeDay(day);
        }
      }
    }
  }

  private addDay(day: number) {
    this.daySet[day] = true;
  }

  private removeDay(day: number) {
    this.daySet[day] = false;
  }

  private containsDay(day: number) {
    return this.daySet[day] ?? false;
  }
}