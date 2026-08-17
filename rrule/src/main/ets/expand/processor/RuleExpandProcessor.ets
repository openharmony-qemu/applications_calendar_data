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

import { Recurrence } from '../../Recurrence';
import { CustomTime, isEmptyStr, Log } from '@ohos/common';
import { FormatTime } from '@ohos/common/src/main/ets/time/FormatTime';
import { Frequency } from '../../Constants';
import { getMaxDayInMonth, isLeapYear } from '@ohos/common/src/main/ets/utils/TimeUtils';
import { DaySet } from './DaySet';

const MAX_ALLOW_ITERATIONS: number = 2000;

// Instances计算挪移时，最多挪移9999年，超出边界则不再处理，避免传入超大interval后挪移计算耗时严重
const MAX_ALLOW_ITERATION_YEAR: number = 9999;

const MAX_ALLOW_ITERATION_MONTH: number = MAX_ALLOW_ITERATION_YEAR * 12;

const MAX_ALLOW_ITERATION_DAY: number = MAX_ALLOW_ITERATION_MONTH * 31;

const MAX_ALLOW_ITERATION_HOUR: number = MAX_ALLOW_ITERATION_DAY * 24;

const MAX_ALLOW_ITERATION_MINUTE: number = MAX_ALLOW_ITERATION_HOUR * 60;

const MAX_ALLOW_ITERATION_SECOND: number = MAX_ALLOW_ITERATION_MINUTE * 60;

const TAG: string = 'RuleExpandProcessor';

/**
 * 循环规则扩展处理器
 */
class RuleExpandProcessor {
  public rangeBegin: number;

  public rangeEnd: number;

  public timeZone: string;

  public count: number = 0;

  public until: number = Number.MAX_VALUE;

  public mIterator: CustomTime = new CustomTime();

  public mGenerated: CustomTime = new CustomTime();

  public mDaySet: DaySet = new DaySet();

  // 标记是否因rrule规则产生的中止扩展
  public isExpandBreakByRule: boolean = false;

  private hasPutSelf: boolean = false;

  constructor(begin: number, end: number, timeZone: string) {
    this.rangeBegin = begin;
    this.rangeEnd = end;
    this.timeZone = timeZone;
    this.mIterator.setTimeZone(timeZone);
    this.mGenerated.setTimeZone(timeZone);
  }

  /**
   * 根据循环规则，扩展实例对应的dtstart数组
   *
   * @param dtStart 日程的dtstart
   * @param rule 循环规则
   * @param outDates 扩展后输出到的数组
   * @param putSelf 是否需要将dtStart自身，放入outDates数组
   */
  public expand(dtStart: number, rule: Recurrence, outDates: number[], isAllDay: boolean, putSelf: boolean = true) {
    if (!rule || !outDates) {
      Log.error(TAG, `expand get invalid params`);
      return;
    }
    Log.info(TAG, `expand ${dtStart} , rule= ${JSON.stringify(rule)}`);
    this.reset();
    if (putSelf) {
      this.putSelfIfNeeded(dtStart, outDates);
    }
    this.initUntil(rule);
    this.mDaySet.rule = rule;
    let failSafe: number = 0;
    this.mIterator.setTime(dtStart);

    let byMonthSize: number = rule.byMonthCount();
    let useByMonth: boolean = rule.useByMonth();
    let useByDay: boolean = rule.useByDay();
    let useByHour: boolean = rule.useByHour();
    let byHourSize: number = rule.byHourCount();
    let useByMinute: boolean = rule.useByMinute();
    let byMinuteSize: number = rule.byMinuteCount();
    let useBySecond: boolean = rule.useBySecond();
    let bySecondSize: number = rule.bySecondCount();

    if (rule.freq === Frequency.MONTHLY && useByDay) {
      // 每月重复的日程，从1号开始计算，避免原始日期是月底，导致某些月份计算时被错过
      this.mIterator.setDate(1);
    }

    events: {
      while (true) {
        if (failSafe++ > MAX_ALLOW_ITERATIONS) {
          Log.warn(TAG, `processing stuck with ${JSON.stringify(rule)}, ${this.rangeBegin}-${this.rangeEnd}`);
          break;
        }
        let iteratorYear: number = this.mIterator.getYear();
        let iteratorMonth: number = this.mIterator.getMonth() + 1;
        let iteratorDay: number = this.mIterator.getDate();
        let iteratorHour: number = this.mIterator.getHourOfDay();
        let iteratorMinute: number = this.mIterator.getMinute();
        let iteratorSecond: number = this.mIterator.getSecond();
        this.mGenerated.clone(this.mIterator);
        let monthIndex: number = 0;
        do {
          // rule中的month取值1-12
          let month: number = useByMonth && (monthIndex < byMonthSize) ? rule.byMonth[monthIndex] : iteratorMonth;
          // month减1变为取值0-11
          month--;
          let dayIndex: number = 1;
          let lastDayToExamine: number = 0;
          if (useByDay) {
            if (rule.freq === Frequency.WEEKLY) {
              const weekStartAdj: number = (this.mIterator.getDayOfWeek() - rule.weekStart + 7) % 7;
              dayIndex = this.mIterator.getDate() - weekStartAdj;
              lastDayToExamine = dayIndex + 6;
            } else {
              lastDayToExamine = getMaxDayInMonth(iteratorYear, month + 1);
            }
          }

          do {
            let day: number = 0;
            if (useByDay) {
              if (!this.mDaySet.contains(iteratorYear, month, dayIndex)) {
                dayIndex++;
                continue;
              } else {
                day = dayIndex;
              }
            } else {
              day = iteratorDay;
            }

            let hourIndex: number = 0;
            do {
              let hour: number = (useByHour && hourIndex < byHourSize) ? rule.byHour[hourIndex] : iteratorHour;

              let minuteIndex: number = 0;
              do {
                let minute: number = (useByMinute && (minuteIndex < byMinuteSize)) ?
                rule.byMinute[minuteIndex] : iteratorMinute;

                let secondIndex: number = 0;
                do {
                  let second: number = (useBySecond && (secondIndex < bySecondSize)) ?
                  rule.bySecond[secondIndex] : iteratorSecond;
                  this.mGenerated.setSafety(iteratorYear, month, day, hour, minute, second);
                  const generateTime: number = this.mGenerated.getTimeInMills();
                  if (generateTime >= dtStart) {
                    const filtered: number = this.filter(rule, this.mGenerated);
                    if (filtered === 0) {
                      // canPreAdd进行预添加判断，判断此generateTime是否之前已经添加到outDates中，避免重复计数
                      const canPreAdd: boolean = (generateTime !== dtStart) || !this.hasPutSelf;
                      if (canPreAdd) {
                        this.count++;
                      }
                      if (generateTime > this.until) {
                        Log.info(TAG, `break by until: ${generateTime} ${this.rangeEnd}`);
                        this.isExpandBreakByRule = true;
                        break events;
                      }
                      if (generateTime >= this.rangeEnd) {
                        Log.info(TAG, `break by end: ${generateTime} ${this.rangeEnd}`);
                        this.isExpandBreakByRule = false;
                        break events;
                      }
                      // 预添加为true的情况下，还需要判断generateTime是否在本次需要扩展的区间范围内，否则直接加到outDates中会产生重复实例
                      if ((generateTime >= this.rangeBegin) && canPreAdd) {
                        outDates.push(generateTime);
                      }
                      if ((rule.count > 0) && (this.count >= rule.count)) {
                        Log.info(TAG, `break by count: ${this.count} ${rule.count}`);
                        this.isExpandBreakByRule = true;
                        break events;
                      }
                    } else {
                      Log.info(TAG,
                        `${iteratorYear} ${month} ${day} ${hour} ${minute} ${second}, filtered ${filtered}`);
                    }
                  }
                  secondIndex++;
                } while (useBySecond && (secondIndex < bySecondSize));
                minuteIndex++;
              } while (useByMinute && (minuteIndex < byMinuteSize));
              hourIndex++;
            } while (useByHour && (hourIndex < byHourSize));
            dayIndex++;
          } while (useByDay && (dayIndex <= lastDayToExamine));
          monthIndex++;
        } while (useByMonth && (monthIndex < byMonthSize));

        this.moveToNextIterator(rule);

        if (this.mIterator.getTimeInMills() <= this.mGenerated.getTimeInMills()) {
          // 挪移后的时间比上一个实例的时间还小，说明日期挪移出现了异常，需要跳出到计算逻辑，避免过多做冗余计算耗时
          Log.warn(TAG, `moveToNextIterator exception ${this.mGenerated.getTimeInMills()} : ${JSON.stringify(rule)}`);
          break events;
        }
      }
    }
  }

  /**
   * 根据排除循环规则，从outDates中排除符合规则的实例dtstart
   *
   * @param dtStart 日程的dtstart
   * @param rule 待排除的循环规则
   * @param outDates 待移除实例dtstart的数组
   */
  public exclude(dtStart: number, rule: Recurrence, outDates: number[], isAllDay: boolean) {
    const needExcludeDates: number[] = [];
    const tempValue: boolean = this.isExpandBreakByRule;
    this.expand(dtStart, rule, needExcludeDates, isAllDay, false);
    // exclude会复用expand方法，exclude逻辑的rrule中止，不计入isExpandBreakByRule，因此需要恢复为复用expand之前的值
    this.isExpandBreakByRule = tempValue;
    needExcludeDates.forEach((date: number) => {
      const index: number = outDates.indexOf(date);
      if ((index >= 0) && (index < outDates.length)) {
        outDates.splice(index, 1);
      }
    });
  }

  private reset() {
    this.count = 0;
    this.until = Number.MAX_VALUE;
    this.isExpandBreakByRule = false;
  }

  private putSelfIfNeeded(dtStart: number, outDates: number[]) {
    if (!this.hasPutSelf &&
      (dtStart >= this.rangeBegin) &&
      (dtStart < this.rangeEnd)) {
      outDates.push(dtStart);
      this.count++;
      this.hasPutSelf = true;
    }
  }

  private initUntil(rule: Recurrence) {
    if (isEmptyStr(rule.until)) {
      return;
    }
    const formatTime: FormatTime = new FormatTime();
    const isParseSuccess: boolean = formatTime.parse(rule.until, this.mIterator);
    if (isParseSuccess) {
      this.until = formatTime.timeStamp;
    }
  }

  /**
   * 判断customTime对应时间，是否满足rule的循环规则
   *
   * @param rule 循环规则
   * @param customTime 待判断的时间
   * @returns 0表示满足规则 其他值代表不满足规则
   */
  private filter(rule: Recurrence, customTime: CustomTime): number {
    let isFound: boolean = false;
    if ((rule.freq <= Frequency.MONTHLY) && (rule.byMonthCount() > 0)) {
      isFound = this.findValueInArray(customTime.getMonth() + 1, rule.byMonth, 0);
      if (!isFound) {
        return 1;
      }
    }
    if ((rule.freq <= Frequency.WEEKLY) && (rule.byWeekCount() > 0)) {
      isFound = this.findValueInArray(customTime.getWeekOfYear(), rule.byWeek, 53);
      if (!isFound) {
        return 2;
      }
    }
    if (rule.freq <= Frequency.DAILY) {
      if (rule.byYearDayCount() > 0) {
        const maxDayOfYear: number = isLeapYear(customTime.getYear()) ? 366 : 365;
        isFound = this.findValueInArray(customTime.getDayOfYear(), rule.byYearDay, maxDayOfYear);
        if (!isFound) {
          return 3;
        }
      }
      if (rule.byMonthDayCount() > 0) {
        const maxDayOfMonth: number = getMaxDayInMonth(customTime.getYear(), customTime.getMonth() + 1);
        isFound = this.findValueInArray(customTime.getDate(), rule.byMonthDay, maxDayOfMonth);
        if (!isFound) {
          return 4;
        }
      }
      if (rule.byWeekDayCount() > 0) {
        isFound = this.findValueInArray(customTime.getDayOfWeek(), rule.byWeekDay, 7);
        if (!isFound) {
          return 5;
        }
      }
    }
    if (rule.freq <= Frequency.HOURLY) {
      isFound = this.findValueInArray(customTime.getHourOfDay(), rule.byHour, 24);
      if (!isFound) {
        return 6;
      }
    }
    if (rule.freq <= Frequency.MINUTELY) {
      isFound = this.findValueInArray(customTime.getMinute(), rule.byMinute, 60);
      if (!isFound) {
        return 7;
      }
    }
    if (rule.freq <= Frequency.SECONDLY) {
      isFound = this.findValueInArray(customTime.getSecond(), rule.bySecond, 60);
      if (!isFound) {
        return 8;
      }
    }
    if (rule.bySetPos && (rule.bySetPos.length > 0)) {
      Log.warn(TAG, `do not support set pos yet`);
      return 9;
    }
    return 0;
  }

  /**
   * 在array中寻找value的值
   *
   * @param value 待查找的值
   * @param array 待查证的array
   * @param negativeOffset 如果array中遇到负值，则加上该偏移量
   */
  private findValueInArray(value: number, array: number[], negativeOffset: number): boolean {
    if (!array || (array.length == 0)) {
      return false;
    }
    let arrayLength: number = array.length;
    for (let index = 0; index < arrayLength; index++) {
      let element: number = array[index];
      if ((element > 0) && (element === value)) {
        return true;
      } else if ((element <= 0) && (element + negativeOffset === value)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 移到下一次需要遍历的时间点：
   * 1.对于按年、月以下循环的，后移一个周期即可
   * 2.对于按年或月循环的，一直后移直到找到一个相同日期的（可过滤29、30、31的无效日期）
   *
   * @param rule 日程的循环规则
   */
  private moveToNextIterator(rule: Recurrence) {
    let oldDay: number = this.mIterator.getDate();
    this.mGenerated.clone(this.mIterator);
    let n: number = 1;
    let interval: number = rule.interval;
    if (interval <= 0) {
      interval = 1;
    }
    while (n < MAX_ALLOW_ITERATIONS) {
      switch (rule.freq) {
        case Frequency.SECONDLY:
          this.mIterator.addSecond(n * interval > MAX_ALLOW_ITERATION_SECOND ? 0 : n * interval);
          break;
        case Frequency.MINUTELY:
          this.mIterator.addMinute(n * interval > MAX_ALLOW_ITERATION_MINUTE ? 0 : n * interval);
          break;
        case Frequency.HOURLY:
          this.mIterator.addHour(n * interval > MAX_ALLOW_ITERATION_HOUR ? 0 : n * interval);
          break;
        case Frequency.DAILY:
          this.mIterator.addDate(n * interval > MAX_ALLOW_ITERATION_DAY ? 0 : n * interval);
          break;
        case Frequency.WEEKLY:
          this.mIterator.addDate(n * 7 * interval > MAX_ALLOW_ITERATION_DAY ? 0 : n * 7 * interval);
          break;
        case Frequency.MONTHLY:
          this.mIterator.addMonth(n * interval > MAX_ALLOW_ITERATION_MONTH ? 0 : n * interval);
          break;
        case Frequency.YEARLY:
          this.mIterator.addYear(n * interval > MAX_ALLOW_ITERATION_YEAR ? 0 : n * interval);
          break;
      }
      if ((rule.freq !== Frequency.YEARLY) && (rule.freq !== Frequency.MONTHLY)) {
        break;
      }
      if (rule.byMonthDayCount() <= 0 || this.mIterator.getDate() === oldDay) {
        break;
      }
      n++;
      this.mIterator.clone(this.mGenerated);
    }
  }
}

export {
  RuleExpandProcessor
};