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
import { DayData, YearData } from '../date/Date';
import { DateManager, YearLunarData, YearLunarStaticData } from '../date/DateManager';
import { allYearLunarStaticData } from '../date/LunarStaicData';
import { CalendarDate } from '../date/CalendarDate';
import { MILLS_OF_MONTH } from '../utils/TimeUtils';


/* Chinese zodiac */
const ZODIAC: string[] =
  ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];
const HEAVENLY_STEMS: string[] =
  ['甲', '乙', '丙', '丁', '戊', '己',
    '庚', '辛', '壬', '癸'];
const JIAN_ZHI: string[] =
  ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

const LUNAR_STRING: string[] = ['零', '一', '二', '三', '四',
  '五', '六', '七', '八', '九', '十'];
/**
 * 12生肖计算时的偏移值
 */
const OFFSET_OF_ZODIAC: number = 4;
/**
 * 12生肖
 */
const SIZE_OF_ZODIAC: number = 12;
const BEGIN_CHINESE_ERA: number = 33;
const OFFSET_OF_TEN = 10;
const OFFSET_OF_TWENTY: number = 20;
/**
 * 农历冬月是11月
 */
const MONTH_OF_DONG_YUE: number = 11;
/**
 * 农历腊月是12月
 */
const MONTH_OF_LA_YUE: number = 12;
/**
 * 农历正月是1月
 */
const MONTH_OF_ZHENG_YUE: number = 1;
//农历月份
const WINTERMONTH: string = '冬月';
const LASTMONTH: string = '腊月';
const FIRSTMONTH: string = '正月';
const MONTH_SIZE: number = 12;
const RUN: string = '闰';

const TAG = 'LunarDateUtil';


/**
 * 验证农历日期是否正确
 * @param lunarYear
 * @param lunarMonth
 * @param lunarLeapMonth
 * @param lunarDay
 * @returns
 */
export function validateLunarDate(lunarYear: number, lunarMonth: number, lunarDay: number) {
  let staticYearData = allYearLunarStaticData.filter((data: YearLunarStaticData) =>
  data.year === lunarYear)[0];
  if (!staticYearData) {
    return false;
  }
  let lunarData = YearLunarData.ConvertFromStaticData(staticYearData)
  let yearData = new YearData(lunarYear);
  DateManager.getInstance().buildYearDataByYearLunarData(yearData, lunarData);
  let allMonthInfo = yearData.getAllMonthInfo();
  for (let i = 0; i < allMonthInfo.length; i++) {
    let lunarMonthInfo = allMonthInfo[i].getDaysInfo();
    for (let index = 0; index < lunarMonthInfo.length; index++) {
      // 判断是否为对应农历月份和日期
      if (lunarMonthInfo[index].lunarDay === lunarDay &&
        lunarMonthInfo[index].lunaMonth === lunarMonth) {
        return true;
      }
    }
  }
  return false;
}

/**
 * 因为农历可能出现一年出现两个相同的月份，比如1年的1月份是冬月，12月份也是冬月。
 * 使用validateLunarDate方法，会导致原本目的是判断1月的冬月是否有三十，结果判断成12月的冬月是否有三十。
 * 因此重新提供一个方法，来判断基准日期附近1个月,是否存在相应农历日期。
 *
 * @param baseDay 基准日期
 * @param lunarDay 农历日期
 * @returns 基准日期附近1个月，是否存在相应农历日期
 */
export function hasLunarDayInRecent(baseDay: DayData, lunarMonth: number, lunarDay: number): boolean {
  let staticYearData = allYearLunarStaticData.filter((data: YearLunarStaticData) =>
  data.year === baseDay.solarYear);
  if (!staticYearData || staticYearData.length === 0) {
    return false;
  }
  let lunarData = YearLunarData.ConvertFromStaticData(staticYearData[0]);
  let yearData = new YearData(baseDay.solarYear);
  DateManager.getInstance().buildYearDataByYearLunarData(yearData, lunarData);
  let allMonthInfo = yearData.getAllMonthInfo();
  for (let i = 0; i < allMonthInfo.length; i++) {
    let lunarMonthInfo = allMonthInfo[i].getDaysInfo();
    for (let index = 0; index < lunarMonthInfo.length; index++) {
      const dayData = lunarMonthInfo[index];
      if (!dayData) {
        continue;
      }
      // 判断是否为对应农历月份和日期
      if (dayData.lunarDay !== lunarDay || dayData.lunaMonth !== lunarMonth) {
        continue;
      }
      // 匹配到相同农历月份和日期后，判断匹配到的农历日期对应的阳历日期是否在目标时间附近
      if (!baseDay.getDate() || !dayData.getDate()) {
        continue;
      }
      const timeOffset = baseDay.getDate().getTime() - dayData.getDate().getTime();
      // 匹配到的日期与目标时间相差在1个月内，认为是准确的匹配；反正，认为是匹配到了错误的农历月份
      if (Math.abs(timeOffset) < MILLS_OF_MONTH) {
        return true;
      }
    }
  }
  return false;
}

/**
 * 判断农历日期对应年份是否与阳历年份一致
 * @param date 阳历日期
 * @returns 农历日期对应年份
 */
export function getLunarYear(date: CalendarDate | Date) {
  // 十月
  const OCTOBER: number = 10;
  // 三月
  const MARCH: number = 3;
  const solarYear = date.getFullYear();
  const solarMonth = date.getMonth();
  let lunarYear = 0;
  const chineseDate: DayData | undefined = DateManager.getInstance().getDayData(date.getFullYear(),
    date.getMonth() + 1, date.getDate()) as DayData;
  let lunarMonth = chineseDate.lunaMonth;
  if (lunarMonth > MONTH_SIZE) {
    lunarMonth = lunarMonth - MONTH_SIZE;
  }
  // 如果阳历月份（一月，二月，三月）对应农历月份（腊月，冬月，十月），对应农历年份-1
  if (lunarMonth >= OCTOBER && solarMonth <= MARCH) {
    lunarYear = solarYear - 1;
  } else {
    lunarYear = solarYear;
  }
  return lunarYear;
}

/**
 * 获取农历月份
 * @param mLunarMonth
 * @returns
 */
export function getChineseMonth(mLunarMonth: number): string {
  let chineseMonth = '';
  let normalMonthStr: string;
  if (mLunarMonth > MONTH_SIZE) {
    normalMonthStr = RUN + getChineseNum(mLunarMonth - MONTH_SIZE) + '月';
  } else {
    normalMonthStr = getChineseNum(mLunarMonth) + '月';
  }
  switch (mLunarMonth) {
    case MONTH_OF_ZHENG_YUE:
      return FIRSTMONTH;
    case MONTH_OF_DONG_YUE:
      return WINTERMONTH;
    case MONTH_OF_LA_YUE:
      return LASTMONTH;
    default:
      break;
  }
  chineseMonth = chineseMonth + normalMonthStr;
  return chineseMonth;
}

/**
 * 农历天数
 * @param date
 * @returns
 */
export function getChineseDay(lunarDay: number): string {
  let chineseDay = '';
  if (lunarDay <= OFFSET_OF_TEN) {
    chineseDay = chineseDay + '初';
  }
  return chineseDay + getChineseNum(lunarDay);
}

/**
 * 农历形式展示数字
 * @param num
 * @returns
 */
function getChineseNum(num: number): string {
  if (num < 0) {
    return '';
  }
  let convertNum = '';

  switch (Math.floor(num / OFFSET_OF_TEN)) {
    case 1: // 大于十小于十九，农历前缀为‘十’
      convertNum = '十';
      break;
    case 2: // 大于二十小于二十九，农历前缀为‘二十’
      if ((num % OFFSET_OF_TWENTY) === 0) {
        convertNum = '二十';
      } else {
        convertNum = '廿';
      }
      break;
    case 3: // 农历三十
      convertNum = '三十';
      break;
    default:
      break;
  }
  let offset = Math.floor(num % OFFSET_OF_TEN);
  if (offset !== 0) {
    convertNum = convertNum + LUNAR_STRING[offset];
  }
  return convertNum;
}
