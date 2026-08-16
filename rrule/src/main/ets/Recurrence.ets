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

import { isEmptyStr } from '@ohos/common/src/main/ets/utils/TextUtils';
import { Frequency, Week } from './Constants';
import { FLAG_WEEK_START, parsePartByKey } from './RecurrenceParser';

const PART_SEPARATOR: string = ';';
const PART_CONNECTOR: string = '=';

/**
 * 循环规则解析后实体
 */
export class Recurrence {
  public freq: Frequency = Frequency.NONE;
  public until: string = '';
  public count: number = 0;
  public interval: number = 0;
  public parseFlag: number = 0;
  public weekStart: Week = Week.UNDEFINED;
  public bySecond: number[] = [];
  public byMinute: number[] = [];
  public byHour: number[] = [];
  // 循环规则之周几
  public byWeekDay: Week[] = [];
  // 循环规则之第几周
  public byWeekNum: number[] = [];
  // 循环规则之几号
  public byMonthDay: number[] = [];
  public byYearDay: number[] = [];
  public byWeek: number[] = [];
  public byMonth: number[] = [];
  public bySetPos: number[] = [];

  public static parse(recurrenceRule: string): Recurrence {
    const recurrence: Recurrence = new Recurrence();
    recurrence.parse(recurrenceRule);
    return recurrence;
  }

  /**
   * 解析循环规则
   *
   * @param recurrenceRule 循环规则字符串
   */
  public parse(recurrenceRule: string) {
    if (isEmptyStr(recurrenceRule)) {
      return;
    }
    const parts: string[] = recurrenceRule.split(PART_SEPARATOR);
    if (!parts || (parts.length <= 0)) {
      return;
    }
    parts.forEach((part: string) => {
      this.parsePart(part);
    });
    if ((this.parseFlag & FLAG_WEEK_START) === 0) {
      this.weekStart = Week.MON;
    }
  }

  /**
   * 封装循环规则为字符串
   *
   * @returns 封装的循环规则字符串
   */
  public format(): string {
    let resultStr: string = '';
    resultStr += this.formatFreq();
    resultStr += this.formatUntil();
    resultStr += this.formatCount();
    resultStr += this.formatInterval();
    resultStr += this.formatWeekStart();
    resultStr += this.formatBySecond();
    resultStr += this.formatByMinute();
    resultStr += this.formatByHour();
    resultStr += this.formatByDay();
    resultStr += this.formatByMonthDay();
    resultStr += this.formatByYearDay();
    resultStr += this.formatByWeek();
    resultStr += this.formatByMonth();
    resultStr += this.formatBySetPos();
    return resultStr;
  }

  public bySecondCount(): number {
    return this.bySecond ? this.bySecond.length : 0;
  }

  public byMinuteCount(): number {
    return this.byMinute ? this.byMinute.length : 0;
  }

  public byHourCount(): number {
    return this.byHour ? this.byHour.length : 0;
  }

  public byWeekDayCount(): number {
    return this.byWeekDay ? this.byWeekDay.length : 0;
  }

  public byWeekNumCount(): number {
    return this.byWeekNum ? this.byWeekNum.length : 0;
  }

  public getWeekNum(index: number): number {
    return ((index >= 0) && (index < this.byWeekNum.length)) ? this.byWeekNum[index] : 0;
  }

  public byMonthDayCount(): number {
    return this.byMonthDay ? this.byMonthDay.length : 0;
  }

  public byYearDayCount(): number {
    return this.byYearDay ? this.byYearDay.length : 0;
  }

  public byWeekCount(): number {
    return this.byWeek ? this.byWeek.length : 0;
  }

  public byMonthCount(): number {
    return this.byMonth ? this.byMonth.length : 0;
  }

  public useBySecond(): boolean {
    return (this.bySecondCount() > 0) && (this.freq > Frequency.SECONDLY);
  }

  public useByMinute(): boolean {
    return (this.byMinuteCount() > 0) && (this.freq > Frequency.MINUTELY);
  }

  public useByHour(): boolean {
    return (this.byHourCount() > 0) && (this.freq > Frequency.HOURLY);
  }

  public useByDay(): boolean {
    return (this.freq >= Frequency.WEEKLY) &&
      ((this.byWeekDayCount() > 0) || (this.byMonthDayCount() > 0));
  }

  public useByMonth(): boolean {
    return (this.byMonthCount()) > 0 && (this.freq > Frequency.MONTHLY);
  }

  /**
   * 是否为最普通的循环规则，即：
   * 每天、每周、每月、每年，且不是自定义的循环（不含until、不含interval、不含count）
   *
   * @returns 是否普通循环
   */
  public isNormalFreq(): boolean {
    if ((this.freq !== Frequency.DAILY) &&
      (this.freq !== Frequency.WEEKLY) &&
      (this.freq !== Frequency.MONTHLY) &&
      (this.freq !== Frequency.YEARLY)) {
      return false;
    }
    if (this.until && (this.until.length > 0)) {
      return false;
    }
    if (this.count > 0) {
      return false;
    }
    if (this.interval > 1) {
      return false;
    }
    return true;
  }

  private parsePart(part: string) {
    if (isEmptyStr(part)) {
      return;
    }
    const splitIndex: number = part.indexOf(PART_CONNECTOR);
    if (!splitIndex || (splitIndex < 0)) {
      return;
    }
    const key: string = part.slice(0, splitIndex);
    const value: string = part.slice(splitIndex + PART_CONNECTOR.length);
    parsePartByKey(key, value, this);
  }

  private formatFreq(): string {
    switch (this.freq) {
      case Frequency.SECONDLY:
        return 'FREQ=SECONDLY';
      case Frequency.MINUTELY:
        return 'FREQ=MINUTELY';
      case Frequency.HOURLY:
        return 'FREQ=HOURLY';
      case Frequency.DAILY:
        return 'FREQ=DAILY';
      case Frequency.WEEKLY:
        return 'FREQ=WEEKLY';
      case Frequency.MONTHLY:
        return 'FREQ=MONTHLY';
      case Frequency.YEARLY:
        return 'FREQ=YEARLY';
      default:
        return '';
    }
  }

  private formatUntil(): string {
    return (this.until && (this.until.length > 0)) ? ';UNTIL=' + this.until : '';
  }

  private formatCount(): string {
    return this.count > 0 ? ';COUNT=' + this.count : '';
  }

  private formatInterval(): string {
    return this.interval > 0 ? ';INTERVAL=' + this.interval : '';
  }

  private formatWeekStart(): string {
    const weekStart: string = weekToString(this.weekStart);
    return (weekStart && (weekStart.length > 0)) ? ';WKST=' + weekStart : '';
  }

  private formatBySecond(): string {
    return (this.bySecond && this.bySecond.length > 0) ? ';BYSECOND=' + this.bySecond.join(',') : '';
  }

  private formatByMinute(): string {
    return (this.byMinute && this.byMinute.length > 0) ? ';BYMINUTE=' + this.byMinute.join(',') : '';
  }

  private formatByHour(): string {
    return (this.byHour && this.byHour.length > 0) ? ';BYHOUR=' + this.byHour.join(',') : '';
  }

  private formatByDay(): string {
    if (!this.byWeekDay || this.byWeekDay.length === 0) {
      return '';
    }
    let resultStr: string = ';BYDAY=';
    this.byWeekDay.forEach((week: Week, index: number) => {
      if (index > 0) {
        resultStr += ',';
      }
      if (index >= 0 && (this.byWeekNum.length > index) && (this.byWeekNum[index] !== 0)) {
        resultStr += this.byWeekNum[index];
      }
      resultStr += weekToString(week);
    });
    return resultStr;
  }

  private formatByMonthDay(): string {
    return (this.byMonthDay && this.byMonthDay.length > 0) ? ';BYMONTHDAY=' + this.byMonthDay.join(',') : '';
  }

  private formatByYearDay(): string {
    return (this.byYearDay && this.byYearDay.length > 0) ? ';BYYEARDAY=' + this.byYearDay.join(',') : '';
  }

  private formatByWeek(): string {
    return (this.byWeek && this.byWeek.length > 0) ? ';BYWEEKNO=' + this.byWeek.join(',') : '';
  }

  private formatByMonth(): string {
    return (this.byMonth && this.byMonth.length > 0) ? ';BYMONTH=' + this.byMonth.join(',') : '';
  }

  private formatBySetPos(): string {
    return (this.bySetPos && this.bySetPos.length > 0) ? ';BYSETPOS=' + this.bySetPos.join(',') : '';
  }
}

function weekToString(week: Week): string {
  switch (week) {
    case Week.MON:
      return 'MO';
    case Week.TUE:
      return 'TU';
    case Week.WED:
      return 'WE';
    case Week.THUR:
      return 'TH';
    case Week.FRI:
      return 'FR';
    case Week.SAT:
      return 'SA';
    case Week.SUN:
      return 'SU';
    default:
      return '';
  }
}