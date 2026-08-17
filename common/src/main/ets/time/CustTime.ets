/**
 * @file Describe the file
 * Copyright (c) 2023-2025 Huawei Device Co., Ltd.
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

import i18n from '@ohos.i18n';
import {
  getMaxDayInMonth,
  HOURS_PER_DAY,
  MILLS_PER_HOUR,
  MILLS_PER_MINUTE,
  MILLS_PER_SECOND,
  MINUTES_PER_HOUR,
  SECONDS_PER_MINUTE } from '../utils/TimeUtils';

const FIELD_YEAR: string = 'year';
const FIELD_WEEK_OF_YEAR: string = 'week_of_year';
const FIELD_MONTH: string = 'month';
const FIELD_DATE: string = 'date';
const FIELD_DAY_OF_YEAR: string = 'day_of_year';
const FIELD_DAY_OF_WEEK: string = 'day_of_week';
const FIELD_HOUR: string = 'hour';
const FIELD_HOUR_OF_DAY: string = 'hour_of_day';
const FIELD_MINUTE: string = 'minute';
const FIELD_SECOND: string = 'second';
const FIELD_ZONE_OFFSET: string = 'zone_offset';
const FIELD_DST_OFFSET: string = 'dst_offset';// 夏令时偏移
const FIELD_JULIAN_DAY: string = 'julian_day';
const TIME_ZONE_UTC: string = 'UTC';

const TAG: string = 'CustomTime';

/**
 * 自定义的时间类，用于处理不同时区之间的差异，内含i18n的Calendar对象
 */
class CustomTime {
  private mCalendar: i18n.Calendar = i18n.getCalendar(i18n.System.getSystemLocale());

  constructor() {
    this.mCalendar.setTimeZone(i18n.getTimeZone().getID());
  }

  public setTimeZone(timeZoneId: string) {
    if (!timeZoneId) {
      timeZoneId = TIME_ZONE_UTC;
    }
    this.mCalendar.setTimeZone(timeZoneId);
  }

  public getTimeZone(): string {
    return this.mCalendar.getTimeZone();
  }

  public setTime(mills: number) {
    this.mCalendar.setTime(mills);
  }

  public getYear(): number {
    this.mCalendar.getFirstDayOfWeek();
    return this.mCalendar.get(FIELD_YEAR);
  }

  /**
   * 获取当前月份
   *
   * @returns 取值0-11,0表示1月，11表示12月
   */
  public getMonth(): number {
    return this.mCalendar.get(FIELD_MONTH);
  }

  public getDate(): number {
    return this.mCalendar.get(FIELD_DATE);
  }

  /**
   * 周日：1、周一：2、周二：3、周三：4、周四：5、周五：6、周六：7
   *
   * @returns 当前日周几对应的数字
   */
  public getDayOfWeek(): number {
    return this.mCalendar.get(FIELD_DAY_OF_WEEK);
  }

  public getDayOfYear(): number {
    return this.mCalendar.get(FIELD_DAY_OF_YEAR);
  }

  public getWeekOfYear(): number {
    return this.mCalendar.get(FIELD_WEEK_OF_YEAR);
  }

  public getHour(): number {
    return this.mCalendar.get(FIELD_HOUR);
  }

  public getHourOfDay(): number {
    return this.mCalendar.get(FIELD_HOUR_OF_DAY);
  }

  public getMinute(): number {
    return this.mCalendar.get(FIELD_MINUTE);
  }

  public getSecond(): number {
    return this.mCalendar.get(FIELD_SECOND);
  }

  public getJulianDay(): number {
    return this.mCalendar.get(FIELD_JULIAN_DAY);
  }

  public getTimeZoneOffset(): number {
    return this.mCalendar.get(FIELD_ZONE_OFFSET);
  }

  public getAllTimeZoneOffset(): number {
    return this.mCalendar.get(FIELD_ZONE_OFFSET) + this.mCalendar.get(FIELD_DST_OFFSET);
  }

  public getGMTStr(): string {
    let timeZoneOffset = this.getAllTimeZoneOffset() / MILLS_PER_MINUTE;
    const symbol = timeZoneOffset >= 0 ? '+' : '-';
    const mTimeZoneOffset = Math.abs(timeZoneOffset);
    let hour = Math.floor(mTimeZoneOffset / MINUTES_PER_HOUR);
    let minuteStr = (mTimeZoneOffset % MINUTES_PER_HOUR).toString().padStart(2, '0');
    let timeStr = `${hour.toString()}:${minuteStr}`;
    let offset = `GMT${symbol}${timeStr}`;
    return offset;
  }

  public getTimeInMills(): number {
    const mills: number = this.mCalendar.getTimeInMillis();
    // 去掉时间戳里面的毫秒数，保留到秒级
    return Math.floor(mills / MILLS_PER_SECOND) * MILLS_PER_SECOND;
  }

  /**
   * Set the time
   *
   * @param { number } year - The year field of the calendar, ranges from 0 to 9999.
   * @param { number } month - The month field of the calendar, ranges from 0 to 11.
   * @param { number } date - The day field of the calendar, ranges from 1 to 31.
   * @param { number } hour - The hour field of the calendar, ranges from 0 to 23.
   * @param { number } minute - The minute field of the calendar, ranges from 0 to 59.
   * @param { number } second - the second field of the calendar, ranges from 0 to 59.
   */
  public set(year: number, month: number, day: number, hour?: number, minute?: number, second?: number) {
    if ((year <= 0) || (year > 9999)) {
      return;
    }
    if ((month < 0) || (month > 11)) {
      return;
    }
    if ((day <= 0) || (day > 31)) {
      return;
    }
    if (hour && (hour < 0 || hour > 23)) {
      return;
    }
    if (minute && (minute < 0 || minute > 59)) {
      return;
    }
    if (second && (second < 0 || second > 59)) {
      return;
    }
    this.mCalendar.set(year, month, day, hour, minute, second);
  }

  public setSafety(year: number, month: number, day: number, hour?: number, minute?: number, second?: number) {
    if (day <= 0) {
      // 当day小于等于0时，当做要往前挪移，先将时间设置到当月1日
      this.set(year, month, 1, hour, minute, second);
      // 再往前挪移对应天数，day为0表示要挪移到当月第0天，即上月最后一天，day为-1表示要往前挪移2天
      this.addDate(day - 1);
      return;
    }
    const maxDayInMonth = getMaxDayInMonth(year, month + 1);
    if (day > maxDayInMonth) {
      // day大于当月最大天数时，要往后挪移，先设置为当月最后一天
      this.set(year, month, maxDayInMonth, hour, minute, second);
      // 再往后挪移超出的天数
      this.addDate(day - maxDayInMonth);
      return;
    }
    this.set(year, month, day, hour, minute, second);
  }

  public clone(customTime: CustomTime) {
    this.mCalendar.setTimeZone(customTime.getTimeZone());
    this.setTime(customTime.getTimeInMills());
  }

  public addYear(value: number) {
    if (value <= 0) {
      return;
    }
    let day: number = this.getDate();
    let month: number = this.getMonth();
    let year: number = this.getYear();
    year += value;
    const maxDayInMonth: number = getMaxDayInMonth(year, month + 1);
    if (day > maxDayInMonth) {
      day = maxDayInMonth;
    }
    this.set(year, month, day);
  }

  public addMonth(value: number) {
    if (value <= 0) {
      return;
    }
    let day: number = this.getDate();
    let month: number = this.getMonth();
    let year: number = this.getYear();
    while (value > 0) {
      month++;
      value--;
      if (month > 11) {
        month = 0;
        year++;
      }
    }
    const maxDayInMonth: number = getMaxDayInMonth(year, month + 1);
    if (day > maxDayInMonth) {
      day = maxDayInMonth;
    }
    this.set(year, month, day);
  }

  public addDate(value: number): void {
    if (value === 0) {
      return;
    }
    if (value < 0) {
      return this.minusDate(value);
    }
    let day: number = this.getDate();
    let month: number = this.getMonth();
    let year: number = this.getYear();
    let maxDatesInMonth: number = getMaxDayInMonth(year, month + 1);
    while (value > 0) {
      if (day + value > maxDatesInMonth) {
        // 若加上value后大于本月最大天数，则月份+1
        month++;
        if (month > 11) {
          month = 0;
          year++;
        }
        value = value - (maxDatesInMonth - day + 1);
        day = 1;
        maxDatesInMonth = getMaxDayInMonth(year, month + 1);
      } else {
        day += value;
        break;
      }
    }
    this.set(year, month, day);
  }

  public addHour(value: number) {
    if (value <= 0) {
      return;
    }
    let hour: number = this.getHourOfDay();
    hour += value;
    if (hour >= HOURS_PER_DAY) {
      let addDay: number = Math.trunc(hour / HOURS_PER_DAY);
      this.addDate(addDay);
      hour %= HOURS_PER_DAY;
      this.setHour(hour);
    } else {
      this.setHour(hour);
    }
  }

  public addMinute(value: number) {
    if (value <= 0) {
      return;
    }
    let minute: number = this.getMinute();
    minute += value;
    if (minute >= MINUTES_PER_HOUR) {
      let addHour: number = Math.trunc(minute / MINUTES_PER_HOUR);
      this.addHour(addHour);
      minute %= MINUTES_PER_HOUR;
      this.setMinute(minute);
    } else {
      this.setMinute(minute);
    }
  }

  public addSecond(value: number) {
    if (value <= 0) {
      return;
    }
    let second: number = this.getSecond();
    second += value;
    if (second >= SECONDS_PER_MINUTE) {
      let addMinute: number = Math.trunc(second / SECONDS_PER_MINUTE);
      this.addMinute(addMinute);
      second %= SECONDS_PER_MINUTE;
      this.setSecond(second);
    } else {
      this.setSecond(second);
    }
  }

  /**
   * 处理addDate接口入参为负数的场景，用于天数往后退的场景
   *
   * @param value 负数，表示消减的天数
   */
  private minusDate(value: number): void {
    if (value >= 0) {
      return;
    }
    let day: number = this.getDate();
    let month: number = this.getMonth();
    let year: number = this.getYear();
    while (value < 0) {
      // 1.当前date挪移指定天数后，仍大于0，即在当月内能处理，则直接处理后break
      if (value + day > 0) {
        day += value;
        break;
      }
      // 2.当前date处理不了，则往前挪移一个月，重新计算date为前一月最后一天、并对value消减，重新循环遍历计算，直到满足条件1
      month--;
      if (month < 0) {
        month = 11;
        year--;
      }
      value = value + day;
      day = getMaxDayInMonth(year, month + 1);
    }
    this.set(year, month, day);
  }

  public setDate(date: number) {
    this.set(this.getYear(), this.getMonth(), date, this.getHourOfDay(), this.getMinute(), this.getSecond());
  }

  private setHour(hour: number) {
    this.set(this.getYear(), this.getMonth(), this.getDate(), hour, this.getMinute(), this.getSecond());
  }

  private setMinute(minute: number) {
    this.set(this.getYear(), this.getMonth(), this.getDate(), this.getHourOfDay(), minute, this.getSecond());
  }

  private setSecond(second: number) {
    this.set(this.getYear(), this.getMonth(), this.getDate(), this.getHourOfDay(), this.getMinute(), second);
  }
}

export {
  CustomTime, TIME_ZONE_UTC
};