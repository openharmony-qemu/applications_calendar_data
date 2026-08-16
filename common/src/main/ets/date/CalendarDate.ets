/**
 * @file Describe the file
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { i18n } from '@kit.LocalizationKit';

const FIELD_YEAR: string = 'year'; // 年
const FIELD_WEEK_OF_YEAR: string = 'week_of_year'; // 一年中的第几周，按照星期计算周，注意：第一周的归属算法各地有区别
const FIELD_MONTH: string = 'month'; // 月
const FIELD_WEEK_OF_MONTH: string = 'week_of_month'; // 一个月中的第几周，按照星期计算周
const FIELD_DATE: string = 'date'; // 日
const FIELD_DAY_OF_YEAR: string = 'day_of_year'; // 一年中的第几天
const FIELD_DAY_OF_WEEK: string = 'day_of_week'; // 一周中的第几天(星期)
const FIELD_WEEK: string = 'dow_local'; // 本地星期
const FIELD_HOUR: string = 'hour'; // 挂钟小时数,可能为12小时
const FIELD_HOUR_OF_DAY: string = 'hour_of_day'; // 一天中的第几小时
const FIELD_MINUTE: string = 'minute'; // 分
const FIELD_SECOND: string = 'second'; // 秒
const FIELD_MILLI_SECOND: string = 'millisecond'; // 毫秒
const FIELD_ZONE_OFFSET: string = 'zone_offset'; // 以毫秒计时的时区固定偏移量(不含夏令时)
const FIELD_DST_OFFSET: string = 'dst_offset'; // 以毫秒计时的夏令时偏移量
const FIELD_JULIAN_DAY: string = 'julian_day'; // 儒略日,与当前时区相关
const FIELD_IS_LEAP_MONTH: string = 'is_leap_month'; // 是否为闰月
const TIME_ZONE_UTC: string = 'UTC'; // UTC时区

// 用于时区管理的Date类
export class CalendarDate {
  // 当前日历存储的时区
  public static timeZone: string = i18n.getTimeZone().getID();
  // calendar日期类 固定公历，时区偏移
  private mCalendar: i18n.Calendar = i18n.getCalendar(i18n.System.getSystemLocale(), 'gregory');
  private mDate: Date = new Date();

  constructor(time?: number | string | Date, monthIndex?: number, date?: number, hours?: number, minutes?: number,
    seconds?: number, ms?: number) {
    this.mCalendar.setTimeZone(CalendarDate.timeZone);
    this.mCalendar.setTime(Date.now());
    if (time === undefined) { // 对应new Date()
      this.mDate.setTime(this.getTime());
    } else if ((typeof time === 'string' || time instanceof Date) && monthIndex === undefined) { // 对应new Date('2024-05-29')
      this.mDate = new Date(time);
      this.set(this.mDate.getFullYear(), this.mDate.getMonth(), this.mDate.getDate(), this.mDate.getHours(),
        this.mDate.getMinutes(), this.mDate.getSeconds(), this.mDate.getMilliseconds());
      this.mDate.setTime(this.getTime());
    } else if (typeof time === 'number' && monthIndex === undefined) { // 对应new Date(1234567890)
      this.mCalendar.setTime(time);
      this.mDate.setTime(this.getTime());
    } else if (typeof time === 'number' && monthIndex !== undefined) { // 对应new Date(2024,4,1)
      const inDate = date ?? 0;
      const inHours = hours ?? 0;
      const inMinutes = minutes ?? 0;
      const inSeconds = seconds ?? 0;
      const inMs = ms ?? 0;
      this.set(time, monthIndex, inDate, inHours,
        inMinutes, inSeconds, inMs);
      this.mDate.setTime(this.getTime());
    } else { // 其他异常情况
      this.mCalendar.setTime(Date.now());
      this.mDate.setTime(this.getTime());
    }
  }

  /**
   * 更新当前时区
   */
  public static updateTimeZone(): void {
    CalendarDate.timeZone = i18n.getTimeZone().getID();
  }
  /**
   * 获取当前时区对应的年月日时分秒对应的日期,用于转换字符串
   * @returns 当前时区的年月日时分秒对应的日期对象
   */
  public getDateInfoByCalendar(): Date {
    return new Date(this.getFullYear(), this.getMonth(), this.getDate(), this.getHours(), this.getMinutes(),
      this.getSeconds(), this.getMilliseconds());
  }

  /**
   * 获取Date对象
   *
   * @returns Date对象
   */
  public getDateInfo(): Date {
    return this.mDate;
  }
  /**
   * 获取时间偏移量（当前时间与日历时间的差值）
   *
   * @returns 时间偏移量（毫秒）
   */
  public getTimeOffset(): number {
    return this.getTime() - this.getDateInfoByCalendar().getTime();
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
  public set(year: number, month: number, day: number, hour?: number, minute?: number, second?: number,
    milliseconds?: number) {
    let setYear = this.getFullYear();
    let setMonth = month;
    let setDay = day;
    let setHour = this.getHours();
    let setMinute = this.getMinutes();
    let setSecond = this.getSeconds();
    let setMilliseconds = this.getMilliseconds();
    if (year > 0 && year < 9999) {
      setYear = year;
    }
    if (hour !== undefined) {
      setHour = hour;
    }
    if (minute !== undefined) {
      setMinute = minute;
    }
    if (second !== undefined) {
      setSecond = second;
    }
    if (milliseconds !== undefined) {
      setMilliseconds = milliseconds;
    }
    this.mCalendar.set(setYear, setMonth, setDay, setHour, setMinute, setSecond);
    this.setMilliseconds(setMilliseconds);
  }

  /**
   * 获取年份
   *
   * @returns 年份（0-9999）
   */
  public getFullYear(): number {
    return this.mCalendar.get(FIELD_YEAR);
  }
  /**
   * 设置年份
   *
   * @param year 年份
   * @param month 月份（可选）
   * @param date 日期（可选）
   * @returns 设置后的时间戳
   */
  public setFullYear(year: number, month?: number, date?: number): number {
    const newMonth = month ?? this.getMonth();
    const newDate = date ?? this.getDate();
    this.set(year, newMonth, newDate, this.getHours(), this.getMinutes(), this.getSeconds());
    return this.getTime();
  }
  /**
   * 获取月份
   *
   * @returns 月份（0-11）
   */
  public getMonth(): number {
    return this.mCalendar.get(FIELD_MONTH);
  }
  /**
   * 设置月份
   *
   * @param month 月份（0-11）
   * @param date 日期（可选）
   * @returns 设置后的时间戳
   */
  public setMonth(month: number, date?: number): number {
    const newDate = date ?? this.getDate();
    this.set(this.getFullYear(), month, newDate, this.getHours(), this.getMinutes(), this.getSeconds());
    return this.getTime();
  }
  /**
   * 获取日期（日）
   *
   * @returns 日期（1-31）
   */
  public getDate(): number {
    return this.mCalendar.get(FIELD_DATE);
  }
  /**
   * 获取一年中的第几天
   *
   * @returns 一年中的第几天
   */
  public getDayOfYear(): number {
    return this.mCalendar.get(FIELD_DAY_OF_YEAR);
  }
  /**
   * 设置日期（日）
   *
   * @param date 日期（1-31）
   * @returns 设置后的时间戳
   */
  public setDate(date: number): number {
    this.set(this.getFullYear(), this.getMonth(), date, this.getHours(), this.getMinutes(), this.getSeconds());
    return this.getTime();
  }
  /**
   * 获取小时数
   *
   * @returns 小时数（0-23）
   */
  public getHours(): number {
    return this.mCalendar.get(FIELD_HOUR_OF_DAY);
  }
  /**
   * 设置小时数
   *
   * @param hours 小时数（0-23）
   * @param minutes 分钟数（可选）
   * @param seconds 秒数（可选）
   * @param milliseconds 毫秒数（可选）
   * @returns 设置后的时间戳
   */
  public setHours(hours: number, minutes?: number, seconds?: number, milliseconds?: number): number {
    const newMinutes = minutes ?? this.getMinutes();
    const newSeconds = seconds ?? this.getSeconds();
    this.set(this.getFullYear(), this.getMonth(), this.getDate(), hours, newMinutes, newSeconds, milliseconds);
    return this.getTime();
  }
  /**
   * 获取分钟数
   *
   * @returns 分钟数（0-59）
   */
  public getMinutes(): number {
    return this.mCalendar.get(FIELD_MINUTE);
  }
  /**
   * 设置分钟数
   *
   * @param minutes 分钟数（0-59）
   * @returns 设置后的时间戳
   */
  public setMinutes(minutes: number): number {
    this.set(this.getFullYear(), this.getMonth(), this.getDate(), this.getHours(), minutes, this.getSeconds());
    return this.getTime();
  }
  /**
   * 获取秒数
   *
   * @returns 秒数（0-59）
   */
  public getSeconds(): number {
    return this.mCalendar.get(FIELD_SECOND);
  }
  /**
   * 设置秒数
   *
   * @param seconds 秒数（0-59）
   * @returns 设置后的时间戳
   */
  public setSeconds(seconds: number): number {
    this.set(this.getFullYear(), this.getMonth(), this.getDate(), this.getHours(), this.getMinutes(), seconds);
    return this.getTime();
  }
  /**
   * 获取时间戳
   *
   * @returns 时间戳（毫秒）
   */
  public getTime(): number {
    return this.mCalendar.getTimeInMillis();
  }
  /**
   * 设置时间戳
   *
   * @param timeStamp 时间戳（毫秒）
   * @returns 设置后的时间戳
   */
  public setTime(timeStamp: number): number {
    this.mCalendar.setTime(timeStamp);
    this.mDate.setTime(timeStamp);
    return this.getTime();
  }
  /**
   * 获取毫秒数
   *
   * @returns 毫秒数（0-999）
   */
  public getMilliseconds(): number {
    return this.mCalendar.get(FIELD_MILLI_SECOND);
  }
  /**
   * 设置毫秒数
   *
   * @param mills 毫秒数（0-999）
   * @returns 设置后的时间戳
   */
  public setMilliseconds(mills: number): number {
    const nowTime = this.getTime();
    const setTime = Math.trunc(nowTime / 1000) * 1000 + mills;
    return this.setTime(setTime);
  }
  /**
   * 获取星期几
   *
   * @returns 星期几（0-6，0表示星期天）
   */
  public getDay(): number {
    return this.mCalendar.get(FIELD_DAY_OF_WEEK) - 1;
  }
  /**
   * 获取儒略日
   *
   * @returns 儒略日
   */
  public getJulianDay(): number {
    return this.mCalendar.get(FIELD_JULIAN_DAY);
  }
  /**
   * 转换为日期字符串
   *
   * @returns 日期字符串
   */
  public toDateString(): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toDateString();
  }
  /**
   * 转换为字符串
   *
   * @returns 日期时间字符串
   */
  public toString(): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toString();
  }
  /**
   * 转换为时间字符串
   *
   * @returns 时间字符串
   */
  public toTimeString(): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toTimeString();
  }
  /**
   * 转换为本地化字符串
   *
   * @param locales 语言环境
   * @param options 格式化选项
   * @returns 本地化日期时间字符串
   */
  public toLocaleString(locales?: (string | string[] | undefined) | Intl.LocalesArgument,
    options?: Intl.DateTimeFormatOptions | undefined): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toLocaleString(locales, options);
  }
  /**
   * 转换为本地化日期字符串
   *
   * @param locales 语言环境
   * @param options 格式化选项
   * @returns 本地化日期字符串
   */
  public toLocaleDateString(locales?: (string | string[] | undefined) | Intl.LocalesArgument,
    options?: Intl.DateTimeFormatOptions | undefined): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toLocaleDateString(locales, options);
  }
  /**
   * 转换为本地化时间字符串
   *
   * @param locales 语言环境
   * @param options 格式化选项
   * @returns 本地化时间字符串
   */
  public toLocaleTimeString(locales?: (string | string[] | undefined) | Intl.LocalesArgument,
    options?: Intl.DateTimeFormatOptions | undefined): string {
    const oDate = this.getDateInfoByCalendar();
    return oDate.toLocaleTimeString(locales, options);
  }
  /**
   * 获取原始值
   *
   * @returns 时间戳
   */
  public valueOf(): number {
    return this.mDate.valueOf();
  }
  /**
   * 获取UTC年份
   *
   * @returns UTC年份
   */
  public getUTCFullYear(): number {
    return this.mDate.getUTCFullYear();
  }
  /**
   * 获取UTC月份
   *
   * @returns UTC月份（0-11）
   */
  getUTCMonth(): number {
    return this.mDate.getUTCMonth();
  }
  /**
   * 获取UTC日期
   *
   * @returns UTC日期（1-31）
   */
  getUTCDate(): number {
    return this.mDate.getUTCDate();
  }
  /**
   * 获取UTC星期几
   *
   * @returns UTC星期几（0-6）
   */
  getUTCDay(): number {
    return this.mDate.getUTCDay();
  }
  /**
   * 获取UTC小时数
   *
   * @returns UTC小时数（0-23）
   */
  getUTCHours(): number {
    return this.mDate.getUTCHours();
  }
  /**
   * 获取UTC分钟数
   *
   * @returns UTC分钟数（0-59）
   */
  getUTCMinutes(): number {
    return this.mDate.getUTCMinutes();
  }
  /**
   * 获取UTC秒数
   *
   * @returns UTC秒数（0-59）
   */
  getUTCSeconds(): number {
    return this.mDate.getUTCSeconds();
  }
  /**
   * 获取UTC毫秒数
   *
   * @returns UTC毫秒数（0-999）
   */
  getUTCMilliseconds(): number {
    return this.mDate.getUTCMilliseconds();
  }
  /**
   * 设置UTC毫秒数
   *
   * @param ms 毫秒数（0-999）
   * @returns 设置后的时间戳
   */
  setUTCMilliseconds(ms: number): number {
    this.mDate.setUTCMilliseconds(ms);
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }
  /**
   * 设置UTC日期
   *
   * @param date 日期（1-31）
   * @returns 设置后的时间戳
   */
  setUTCDate(date: number): number {
    this.mDate.setUTCDate(date);
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }
  /**
   * 设置UTC月份
   *
   * @param month 月份（0-11）
   * @param date 日期（可选）
   * @returns 设置后的时间戳
   */
  setUTCMonth(month: number, date?: number | undefined): number {
    this.mDate.setUTCMonth(month, date ?? this.mDate.getUTCDate());
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }
  /**
   * 设置UTC年份
   *
   * @param year 年份
   * @param month 月份（可选）
   * @param date 日期（可选）
   * @returns 设置后的时间戳
   */
  setUTCFullYear(year: number, month?: number | undefined, date?: number | undefined): number {
    this.mDate.setUTCFullYear(year, month ?? this.mDate.getUTCMonth(), date ?? this.mDate.getUTCDate());
    this.mCalendar.setTime(this.mDate.getTime());
    return this.getTime();
  }
  /**
   * 转换为UTC字符串
   *
   * @returns UTC日期时间字符串
   */
  toUTCString(): string {
    return this.getDateInfoByCalendar().toUTCString();
  }
  /**
   * 转换为ISO格式字符串
   *
   * @returns ISO 8601格式字符串
   */
  toISOString(): string {
    return this.getDateInfoByCalendar().toISOString();
  }
  /**
   * 转换为JSON字符串
   *
   * @param JSON序列化的键
   * @returns JSON字符串
   */
  toJSON(key?: string | number | boolean): string {
    return this.getDateInfoByCalendar().toJSON(key);
  }  
  /**
   * 设置单个对象时区
   * @param timeZone
   */
  setTimeZone(timeZone: string) {
    this.mCalendar.setTimeZone(timeZone);
  }

  /**
   * 获取时区
   *
   * @returns 时区字符串
   */
  getTimeZone(): string {
    return this.mCalendar.getTimeZone();
  }
}