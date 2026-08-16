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

import { DayData, MonthInfo, YearData } from './Date';
import { allYearLunarStaticData } from './LunarStaicData';
import { AccessCountMap } from '../templates/AccessCountMap';
import { Log } from '../utils/Log';

const TAG: string = `DateManager`;

export class DateManager {
  private static INSTANCE: DateManager = new DateManager();
  public today: DayData;
  private allYearData: AccessCountMap<number, YearData> = new AccessCountMap<number, YearData>(50);
  private allYearLunarData: AccessCountMap<number, YearLunarData> = new AccessCountMap<number, YearLunarData>(50);
  // 设置选中天信息, 某天某月某日,全局唯一
  private _selectDay: DayData | null | undefined = null;

  constructor() {
    // 触发初始化
    this.today = DayData.buildByDate(new Date());
  }

  public get selectedDay(): DayData {
    if (!this._selectDay) {
      this._selectDay = DayData.buildByDate(new Date());
    }
    return this._selectDay;
  }

  static getInstance(): DateManager {
    return DateManager.INSTANCE;
  }

  public onSystemDateChange(): void {
    // 触发初始化
    Log.info(TAG, `onSystemDateChange`);
    this.today.isToday = false;
    const newToday = new Date();
    let newDayData = this.getDayData(newToday.getFullYear(), newToday.getMonth() + 1, newToday.getDate());
    if (newDayData) {
      this.today = newDayData;
      this.today.isToday = true;
    }
  }

  public getDayData(solarYear: number, solarMonth: number, solarDay: number): DayData | undefined {
    return this.getYearData(solarYear)?.getMonthInfo(solarMonth)?.getDayData(solarDay);
  }

  public getYearData(solarYear: number): YearData | undefined {
    // get from memory cache
    if (solarYear <= 0) {
      return undefined;
    }

    if (!this.allYearData.has(solarYear)) {
      let yearData = new YearData(solarYear);
      this.allYearData.set(solarYear, yearData);

      // get lunar data from memory
      let lunarData = this.getYearLunarData(solarYear);
      if (!lunarData) {
        return undefined;
      }

      if (lunarData) {
        this.buildYearDataByYearLunarData(yearData, lunarData);
      }
      // 对于前后10年的年份，多触发几次get，增加count
      const nearByYear = 10;
      if (solarYear <= this.today.solarYear + nearByYear && solarYear >= this.today.solarYear - nearByYear) {
        this.allYearData.get(solarYear);
      }
    }
    return this.allYearData.get(solarYear);
  }

  /*
   get year lunar info
   * */
  public getYearLunarData(solarYear: number): YearLunarData | undefined {
    // query by year
    if (!this.allYearLunarData.has(solarYear)) {
      //  if query failed calculate now, start an async work to insert db
      let staticYearData = allYearLunarStaticData.filter((data: YearLunarStaticData) => data.year === solarYear)[0];
      if (!staticYearData) {
        return undefined;
      }
      let yearLunarData = YearLunarData.ConvertFromStaticData(staticYearData)
      this.allYearLunarData.set(solarYear, yearLunarData)
    }
    return this.allYearLunarData?.get(solarYear);
  }

  buildYearDataByYearLunarData(yearData: YearData, lunarData: YearLunarData): void {
    let allMonthInfo = yearData.getAllMonthInfo();
    for (let index = 0; index < allMonthInfo.length; index++) {
      let monthLunarInfo = lunarData.getMonthLunarInfo(allMonthInfo[index].getMonth())
      if (index === 1) {
        // 通过春节初一计算除夕，所以需要把上一个月的数据传入，初一只会出现在公历一月、二月，且除夕不会出现在12月，22085年才会出现春节初一与元旦同一天
        this.buildMonthLunarData(allMonthInfo[index], monthLunarInfo);
      } else {
        this.buildMonthLunarData(allMonthInfo[index], monthLunarInfo);
      }
    }
  }

  // 生成每月的农历信息
  buildMonthLunarData(monthInfo: MonthInfo, solarLunarDays: SolarLunarInfo[]): void {
    let daysInfo = monthInfo.getDaysInfo();
    let index = 0;
    for (let i = 0; i < solarLunarDays.length; ++i) {
      let startLunarDay = solarLunarDays[i].lunarDay;
      let startLunarMonth = solarLunarDays[i].lunarMonth;

      let endSolarDay = daysInfo.length; // default
      if (i + 1 !== solarLunarDays.length) {
        endSolarDay = solarLunarDays[i + 1].solarDay - 1;
      }

      for (; index < endSolarDay; ++index) {
        daysInfo[index].lunaMonth = startLunarMonth;
        daysInfo[index].lunarDay = startLunarDay;
        startLunarDay += 1;
      }
    }
  }
}

export interface YearLunarStaticData {
  year: number;
  solarLunars: number[]
  lunarTerms: number[]
}

export class YearLunarData {
  public year: number;
  public _solarLunarDays: SolarLunarInfo[] = [];

  constructor(year: number) {
    this.year = year;
  }

  private _lunarTermInfos: LunarTermInfo[] = [];

  public get lunarTermInfos(): LunarTermInfo[] {
    return this._lunarTermInfos;
  }

  static ConvertFromStaticData(data: YearLunarStaticData): YearLunarData {
    let yearData = new YearLunarData(data.year)
    data.solarLunars.forEach((item: number) => {
      yearData._solarLunarDays.push(SolarLunarInfo.fromHexData(item));
    })
    data.lunarTerms.forEach((item: number) => {
      yearData._lunarTermInfos.push(LunarTermInfo.fromHexData(item));
    })
    return yearData;
  }

  getMonthLunarInfo(month: number): SolarLunarInfo[] {
    return this._solarLunarDays.filter((info: SolarLunarInfo) => info.solarMonth === month);
  }
}

export class SolarLunarInfo {
  private static readonly solarMonthOffset: number = 24;
  private static readonly solarDayOffset: number = 16;
  private static readonly lunarMonthOffset: number = 8;
  public solarMonth: number;
  public solarDay: number;
  public lunarMonth: number;
  public lunarDay: number;

  constructor(solarMonth: number, solarDay: number, lunarMonth: number, lunarDay: number) {
    this.solarMonth = solarMonth;
    this.solarDay = solarDay;
    this.lunarMonth = lunarMonth;
    this.lunarDay = lunarDay;
  }

  static fromHexData(hex: number) {
    const solarMonth = (hex & 0xf000000) >> SolarLunarInfo.solarMonthOffset;
    const solarDay = (hex & 0xff0000) >> SolarLunarInfo.solarDayOffset;
    const lunarMonth = (hex & 0xff00) >> SolarLunarInfo.lunarMonthOffset;
    const lunarDay = (hex & 0xff);
    return new SolarLunarInfo(solarMonth, solarDay, lunarMonth, lunarDay)
  }

  isEqual(other: SolarLunarInfo): boolean {
    return this.solarMonth === other.solarMonth &&
      this.solarDay === other.solarDay &&
      this.lunarMonth === other.lunarMonth &&
      this.lunarDay === other.lunarDay;
  }

  /*
   0xABBCCDD
  A：solarMonth
  BB：solarDay
  CC：lunarMonth
  DD：lunarDay
  */
  toHexData(): number {
    return (this.solarMonth << SolarLunarInfo.solarMonthOffset) | (this.solarDay << SolarLunarInfo.solarDayOffset) |
      (this.lunarMonth << SolarLunarInfo.lunarMonthOffset) | (this.lunarDay);
  }

  toHexStr(): string {
    return '0x' + this.toHexData().toString(16); // 16 is hex
  }
}

export class LunarTermInfo {
  private static readonly solarMonthOffset: number = 16;
  private static readonly solarDayOffset: number = 8;
  public solarDay: number
  public solarMonth: number
  public termIndex: number

  constructor(solarMonth: number, solarDay: number, termIndex: number) {
    this.solarMonth = solarMonth
    this.solarDay = solarDay
    this.termIndex = termIndex
  }

  static fromHexData(hex: number) {
    let solarMonth = (hex & 0xf0000) >> LunarTermInfo.solarMonthOffset;
    let solarDay = (hex & 0xff00) >> LunarTermInfo.solarDayOffset;
    let termIndex = (hex & 0xff);
    return new LunarTermInfo(solarMonth, solarDay, termIndex)
  }

  isEqual(other: LunarTermInfo): boolean {
    return this.solarMonth === other.solarMonth &&
      this.solarDay === other.solarDay &&
      this.termIndex === other.termIndex
  }

  /*
  0xABBCC
  A：solarMonth
  BB：solarDay
  C：termIndex
  */
  toHexData(): number {
    return (this.solarMonth << LunarTermInfo.solarMonthOffset) |
      (this.solarDay << LunarTermInfo.solarDayOffset) | (this.termIndex)
  }

  toHexStr(): string {
    return '0x' + this.toHexData().toString(16); // 16 is hex
  }
}