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

import intl from '@ohos.intl';
import { i18n } from '@kit.LocalizationKit';

export const HOURS_PER_DAY = 24;

export const MINUTES_PER_HOUR = 60;

export const SECONDS_PER_MINUTE = 60;

export const MILLS_PER_SECOND = 1000;

export const MILLS_PER_MINUTE = MILLS_PER_SECOND * 60;

// 一天分钟数
export const MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;

export const MILLS_PER_HOUR = MILLS_PER_MINUTE * 60;

export const MILLS_PER_DAY = MILLS_PER_HOUR * 24;

export const MILLS_PER_WEEK = MILLS_PER_DAY * 7;

export const MILLS_OF_MONTH = MILLS_PER_DAY * 31;

export const YEAR_UPPER_LIMIT = 2100;

export const YEAR_LOWER_LIMIT = 1900;

export const MONTH_COUNT_PER_YEAR = 12;

export const MAX_MONTH_IN_CALENDAR = 11;

export const MIN_MONTH_IN_CALENDAR = 0;

export const MAX_DAY_PER_MONTH = 31;

export const DAY_LOWER_LIMIT = 1;

export const HOUR_LOWER_LIMIT = 0;

export const MINUTE_LOWER_LIMIT = 0;

export const SECONDS_LOWER_LIMIT = 0;

export const DAY_PER_WEEK: number = 7;

export const MAX_WEEK_PER_MONTH: number = 5;

export const MAX_WEEK_PER_YEAR: number = 53;

export const MAX_DAY_PER_YEAR: number = 366;

// 正则表达式：匹配中文下的日历时间
// eg：“上午8:00”
const regularExpr: RegExp = new RegExp('/([\u4E00-\u9FA5][\u4E00-\u9FA5])(1?[0-2]|[1-9]):([0-5][0-9])/g');

// 中文：上午，下午
const enum AmOrPmChinese { AM_CHINESE = '上午', PM_CHINESE = '下午' };

// 中文风格：上午，下午
const enum AmOrPmChineseStyle {

  MIDNIGHT = '半夜',

  BEFORE_DAWN = '凌晨',

  DAWN = '清晨',

  EARLY_MORNING = '早上',

  MORNING = '上午',

  NOON = '中午',

  AFTERNOON = '下午',

  DUSK = '傍晚',

  EVENING = '晚上'
}

// 12小时制下，上午时间的中文显示
const amChineseStyleMap: Map<number, string> = new Map([
  [1, AmOrPmChineseStyle.BEFORE_DAWN],
  [2, AmOrPmChineseStyle.BEFORE_DAWN],
  [3, AmOrPmChineseStyle.BEFORE_DAWN],
  [4, AmOrPmChineseStyle.BEFORE_DAWN],
  [5, AmOrPmChineseStyle.DAWN],
  [6, AmOrPmChineseStyle.DAWN],
  [7, AmOrPmChineseStyle.EARLY_MORNING],
  [8, AmOrPmChineseStyle.EARLY_MORNING],
  [9, AmOrPmChineseStyle.MORNING],
  [10, AmOrPmChineseStyle.MORNING],
  [11, AmOrPmChineseStyle.NOON],
  [12, AmOrPmChineseStyle.MIDNIGHT],
]);

// 12小时制下，下午时间的中文显示
const pmChineseStyleMap: Map<number, string> = new Map([
  [1, AmOrPmChineseStyle.AFTERNOON],
  [2, AmOrPmChineseStyle.AFTERNOON],
  [3, AmOrPmChineseStyle.AFTERNOON],
  [4, AmOrPmChineseStyle.AFTERNOON],
  [5, AmOrPmChineseStyle.DUSK],
  [6, AmOrPmChineseStyle.DUSK],
  [7, AmOrPmChineseStyle.EVENING],
  [8, AmOrPmChineseStyle.EVENING],
  [9, AmOrPmChineseStyle.EVENING],
  [10, AmOrPmChineseStyle.EVENING],
  [11, AmOrPmChineseStyle.MIDNIGHT],
  [12, AmOrPmChineseStyle.NOON],
]);

const MAX_DAY_IN_MONTH: Record<number, number> = {
  1: 31,
  3: 31,
  4: 30,
  5: 31,
  6: 30,
  7: 31,
  8: 31,
  9: 30,
  10: 31,
  11: 30,
  12: 31
};

// 对DateTimeFormat进行弱引用缓存，避免频繁创建导致内存峰值升高
const TIME_FORMAT_CACHE: Map<string, WeakRef<intl.DateTimeFormat>> = new Map();

/**
 * 获取当前设备所在时区与UTC时区时间差值的毫秒数
 */
export function getCurrentTimeZoneMillisecond(date: Date): number {
  return -date.getTimezoneOffset() * MILLS_PER_MINUTE;
}

/**
 * 根据系统语言，使用intl和i18n进行时间格式化
 *
 * @param date 日期
 * @param systemLanguage 系统语言
 * @param timeZone 时区
 * @param is24Hour 是否24小时制
 * @return 格式化后的字符串
 */
function formatTimeString(date: Date, systemLanguage: string, timeZone: string, is24Hour: boolean): string {
  const formatKey: string = `${systemLanguage}_${timeZone}_${is24Hour}`;
  // 尝试从弱引用中获取缓存的Format对象，复用直接格式化时间
  const cachedTimeFormat: intl.DateTimeFormat | undefined = TIME_FORMAT_CACHE.get(formatKey)?.deref();
  if (cachedTimeFormat) {
    return cachedTimeFormat.format(date);
  }
  // 没有缓存的Format对象，重新创建一个Format对象
  const locale = new intl.Locale(systemLanguage ? systemLanguage : i18n.System.getSystemLanguage());
  let dateTimeOptions: intl.DateTimeOptions = {
    hour: 'numeric',
    minute: '2-digit',
    hour12: !is24Hour,
    timeZone: timeZone
  }
  const newTimeFormat = new intl.DateTimeFormat(locale.toString(), dateTimeOptions);
  // 并将新创建的Format对象放入弱引用缓存中
  TIME_FORMAT_CACHE.set(formatKey, new WeakRef(newTimeFormat));
  return newTimeFormat.format(date);
}

/**
 * 根据系统语言，使用intl和i18n进行日期格式化 (12小时制进行中文本土化特殊处理)
 *
 * @param date 日期
 * @param dateTimeOptions 格式化选项
 */
export function formatTimeChineseStyle(date: Date, timeZone: string, is24Hour?: boolean): string {
  const systemLanguage: string = i18n.System.getSystemLanguage();
  if (is24Hour === undefined) {
    // 若调用时已传24小时制要求，使用传参进行format，若未传则默认获取系统24小时制配置
    is24Hour = i18n.System.is24HourClock();
  }
  let dateString = formatTimeString(date, systemLanguage, timeZone, is24Hour);
  // 中文语言和12小时制下对时间本土化特殊处理
  const isChineseLanguage = systemLanguage.split('-')[0].toLocaleLowerCase() === 'zh';
  if (isChineseLanguage && !is24Hour) {
    // 对正则表达式的指针位置 0 处理
    regularExpr.lastIndex = 0;
    // 根据正则表达式正则匹配中文 12 小时制时间
    let matchDateFormat: Record<number, string> | null = regularExpr.exec(dateString);
    if (matchDateFormat != null) {
      // 正则匹配的“上午”和 “下午”
      const amOrPmReg = matchDateFormat[1];
      // 正则匹配的“小时”
      const hourReg = Number(matchDateFormat[2]);
      // 正则匹配的“分钟”
      const minuteReg = matchDateFormat[3];
      const amOrPmChineseStyle = transDateFormatToChineseStyle(amOrPmReg, hourReg);
      dateString = dateString.replace(amOrPmReg, amOrPmChineseStyle);
    }
  }
  return dateString;
}

/**
 * 对 12小时制 进行中文本土化特殊处理：如 “上午” 转换为 “半夜”
 *
 * @param amOrPm “上午”和 “下午”
 * @param hour 小时
 * @return 格式化后的字符串
 * 规则：
 * 上午1:00 =< time < 上午5:00 : 凌晨
 * 上午5:00 =< time < 上午7:00 : 清晨
 * 上午7:00 =< time < 上午9:00 : 早上
 * 上午9:00 =< time < 上午11:00 : 上午
 * 上午11:00 =< time < 下午1:00 : 中午
 * 下午1:00 =< time < 下午5:00 : 下午
 * 下午5:00 =< time < 下午7:00 : 傍晚
 * 下午7:00 =< time < 下午11:00 : 晚上
 * 下午11:00 =< time < 上午1:00 : 半夜
 */
export function transDateFormatToChineseStyle(amOrPm: string, hour: number): string {
  if (amOrPm === AmOrPmChinese.AM_CHINESE) {
    const str = amChineseStyleMap.get(hour);
    if (typeof str === 'string') {
      return str + '';
    }
  } else if (amOrPm === AmOrPmChinese.PM_CHINESE) {
    const str = pmChineseStyleMap.get(hour);
    if (typeof str === 'string') {
      return str + '';
    }
  }
  return '';
}

export function isLeapYear(year: number): boolean {
  return (year % 4 === 0) && ((year % 100 !== 0) || (year % 400 === 0));
}

/**
 * 获取一个月最多有多少天
 *
 * @param year 年份，用于判断闰年
 * @param realMonth 真实月份，1-12 1表示1月 12表示12月
 * @returns 当年当月的天数
 */
export function getMaxDayInMonth(year: number, realMonth: number): number {
  if (realMonth > 12) {
    realMonth %= 12;
  }
  if (realMonth === 2) {
    const isLeapYear: boolean = (year % 4 === 0) && ((year % 100 !== 0) || (year % 400 === 0));
    return isLeapYear ? 29 : 28;
  } else {
    return MAX_DAY_IN_MONTH[realMonth];
  }
}