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

import { Recurrence } from '../../Recurrence';
import { CustomTime, getLunarYear, hasLunarDayInRecent, isEmptyStr, Log } from '@ohos/common';
import { FormatTime } from '@ohos/common/src/main/ets/time/FormatTime';
import { DaySet } from './DaySet';
import { DayData, YearData } from '@ohos/common/src/main/ets/date/Date';
import { DateManager, YearLunarData, YearLunarStaticData } from '@ohos/common/src/main/ets/date/DateManager';
import { allYearLunarStaticData } from '@ohos/common/src/main/ets/date/LunarStaicData';
import { Frequency } from '../../Constants';
import { i18n } from '@kit.LocalizationKit';

const MAX_ALLOW_ITERATIONS: number = 2000;
const MAX_SUPPORT_LUNAR_YEAR: number = 2100;
const MONTH_SIZE: number = 12;
const MAX_MONTH_DAY: number = 30;
const TAG: string = 'LunarRuleExpandProcessor';

/**
 * 循环规则扩展处理器
 */
class LunarRuleExpandProcessor {
  public rangeBegin: number;

  public rangeEnd: number;

  public timeZone: string;

  public count: number = 0;

  private hasPutSelf: boolean = false;

  public until: number = Number.MAX_VALUE;

  public mIterator: CustomTime = new CustomTime();

  public mGenerated: CustomTime = new CustomTime();

  public mDaySet: DaySet = new DaySet();

  // 标记是否因rrule规则产生的中止扩展
  public isExpandBreakByRule: boolean = false;

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
  public expand(dtStart: number, rule: Recurrence, outDates: number[], putSelf: boolean = true) {
    if (!rule || !outDates) {
      Log.error(TAG, `expand get invalid params`);
      return;
    }
    Log.info(TAG, `expand ${dtStart} , rule= ${JSON.stringify(rule)}`);
    this.reset();
    // 计算dtStart对应实例
    if (putSelf) {
      this.putSelfIfNeeded(dtStart, outDates);
    }
    this.initUntil(rule);
    this.mIterator.setTime(dtStart);
    const hour: number = this.mIterator.getHourOfDay();
    const minute: number = this.mIterator.getMinute();
    const second: number = this.mIterator.getSecond();
    const date = new Date(this.mIterator.getTimeInMills());
    // 初始化原始农历年月日信息
    const sourceLunarDay: DayData = DateManager.getInstance().getDayData(date.getFullYear(),
      date.getMonth() + 1, date.getDate()) as DayData;
    this.mGenerated.clone(this.mIterator);
    // 遍历的目标农历年份，从初始农历年份开始计算
    let iteratorYear = getLunarYear(date);
    let failSafe: number = 0;
    events: {
      while (true) {
        if (failSafe++ > MAX_ALLOW_ITERATIONS) {
          Log.warn(TAG, `processing stuck with ${JSON.stringify(rule)}, ${this.rangeBegin}-${this.rangeEnd}`);
          break;
        }
        if (iteratorYear > MAX_SUPPORT_LUNAR_YEAR) {
          break;
        }
        // 预计算该年份可能存在的农历实例开始时间
        let tempMillis = this.getTempMillis(sourceLunarDay, iteratorYear, hour, minute, second);
        for (let i = 0; i < tempMillis.length; i++) {
          const canPreAdd: boolean = (tempMillis[i] !== dtStart) || !this.hasPutSelf;
          if (canPreAdd) {
            this.count++;
          }
          if (tempMillis[i] >= this.rangeEnd) {
            Log.info(TAG, `break by end: ${tempMillis[i]} ${this.rangeEnd}`);
            this.isExpandBreakByRule = false;
            break events;
          }
          if (tempMillis[i] > this.until) {
            Log.info(TAG, `break by until: ${tempMillis[i]} ${this.rangeEnd}`);
            this.isExpandBreakByRule = true;
            break events;
          }
          if ((tempMillis[i] >= this.rangeBegin) && canPreAdd && tempMillis[i] >= dtStart) {
            // 按rrule规则按需，将日程实例开始时间加入结果集
            outDates.push(tempMillis[i]);
          }
        }
        if ((rule.count > 0) && (this.count >= rule.count)) {
          Log.info(TAG, `break by count: ${this.count} ${rule.count}`);
          this.isExpandBreakByRule = true;
          break events;
        }
        // 计算完一年的实例，增加1年开始计算下一年的
        iteratorYear++;
      }
    }
    this.moveToNextIterator(rule);
    return outDates;
  }

  /**
   * 根据农历日期获取对应阳历日期并转换为时间戳
   * @param sourceLunar
   * @returns
   */
  private getTempMillis(sourceLunar: DayData, iteratorYear: number, hour: number, minutes: number, seconds: number) {
    let tempMillis: number[] = [];
    // 获取iteratorYear对应年份的全年静态农历配置信息
    let staticYearData = allYearLunarStaticData.filter((data: YearLunarStaticData) => data.year === iteratorYear);
    if (!staticYearData || staticYearData.length < 1) {
      Log.error(TAG, `getTempMillis static year date is null!`);
      return [];
    }
    // 根据农历静态配置，转换计算出全年的农历日期信息
    let yearLunarData = YearLunarData.ConvertFromStaticData(staticYearData[0])
    let yearData = new YearData(iteratorYear);
    // 将农历信息拷贝到yearData中
    DateManager.getInstance().buildYearDataByYearLunarData(yearData, yearLunarData);

    // 遍历一年内所有日期，筛选出农历年月日，与初始农历日期匹配的时间
    let allMonthInfo = yearData.getAllMonthInfo();
    let dayData: DayData;
    for (let i = 0; i < allMonthInfo.length; i++) {
      let lunarMonthInfo = allMonthInfo[i].getDaysInfo();
      for (let index = 0; index < lunarMonthInfo.length; index++) {
        dayData = lunarMonthInfo[index];
        if (!dayData) {
          continue;
        }
        if (!this.isLunarDateMatched(sourceLunar, dayData)) {
          continue;
        }
        // 日期匹配成功，且是有效日期，加到结果集合中
        let solarDay = dayData.solarDay;
        let solarMonth = dayData.solarMonth - 1;
        // 通过CustomTime计算准确的时分秒
        this.mGenerated.set(iteratorYear, solarMonth, solarDay, hour, minutes, seconds);
        const solarDate = new Date(this.mGenerated.getTimeInMills());
        // 通过Date设置准确的年月日
        solarDate.setFullYear(iteratorYear, solarMonth, solarDay);
        const solarDateTime = solarDate.getTime();
        tempMillis.push(solarDateTime);
      }
    }
    return tempMillis;
  }

  private isLunarDateMatched(sourceLunar: DayData, targetLunar: DayData): boolean {
    return this.matchLunarDay(sourceLunar, targetLunar) && this.matchLunarMonth(sourceLunar, targetLunar);
  }

  private matchLunarDay(sourceLunar: DayData, targetLunar: DayData): boolean {
    if (targetLunar.lunarDay === sourceLunar.lunarDay) {
      return true;
    }
    // 涉及三十转二十九场景，特殊处理
    if (sourceLunar.lunarDay === MAX_MONTH_DAY && targetLunar.lunarDay === MAX_MONTH_DAY - 1) {
      // 需要判断该月是否存在农历三十，若存在三十，则二十九不符合条件；若不存在三十，则二十九符合条件。
      if (hasLunarDayInRecent(targetLunar, targetLunar.lunaMonth, MAX_MONTH_DAY)) {
        return false;
      } else {
        return true;
      }
    }
    // 日期不匹配，且不是三十转二十九场景，判定为不符合条件
    return false;
  }

  private matchLunarMonth(sourceLunar: DayData, targetLunar: DayData): boolean {
    if (targetLunar.lunaMonth === sourceLunar.lunaMonth) {
      // 月份完全相同，即目标月份和原始月份都是非闰月或者都是闰月，符合条件
      return true;
    } else if (targetLunar.lunaMonth === (sourceLunar.lunaMonth - MONTH_SIZE)) {
      // 目标月份是非闰月，原始月份是闰月，月份相同，符合条件（闰月日程需要在非闰月显示）
      return true;
    } else if ((targetLunar.lunaMonth - MONTH_SIZE) === sourceLunar.lunaMonth) {
      // 目标月份是闰月，原始月份是非闰月，月份相同，按新要求不符合条件（非闰月日程不在闰月显示）
      return false;
    } else {
      // 月份完全不相同，不符合条件
      return false;
    }
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
    while (true) {
      if (rule.freq === Frequency.YEARLY) {
        this.mIterator.addYear(n * interval);
        break;
      }
      if (this.mIterator.getDate() === oldDay) {
        break;
      }
      n++;
      this.mIterator.clone(this.mGenerated);
    }
  }

  /**
   * 根据排除循环规则，从outDates中排除符合规则的实例dtstart
   *
   * @param dtStart 日程的dtstart
   * @param rule 待排除的循环规则
   * @param outDates 待移除实例dtstart的数组
   */
  public exclude(dtStart: number, rule: Recurrence, outDates: number[]) {
    const needExcludeDates: number[] = [];
    const tempValue: boolean = this.isExpandBreakByRule;
    this.expand(dtStart, rule, needExcludeDates, false);
    // exclude会复用expand方法，exclude逻辑的rrule中止，不计入isExpandBreakByRule，因此需要恢复为复用expand之前的值
    this.isExpandBreakByRule = tempValue;
    needExcludeDates.forEach((date: number) => {
      const index: number = outDates.indexOf(date);
      if ((index >= 0) && (index < outDates.length)) {
        outDates.splice(index, 1);
      }
    });
  }
}

export {
  LunarRuleExpandProcessor
};