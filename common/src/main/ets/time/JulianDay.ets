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

/**
 * 根据公历的年月日，获取儒略历对应的儒略日
 * (通用算法)
 *
 * @param year 年份
 * @param month 月份
 * @param monthDay 该月日期
 */
export function getJulianDay(year: number, month: number, monthDay: number): number {
  let num = 0;
  if (month <= 2) {
    month += 12;
    year -= 1;
  }
  if (year * 372 + month * 31 + monthDay >= 588829) {
    num = Math.floor(year / 100);
    num = 2 - num + Math.floor(year / 400);
  }
  const day: number = monthDay + 0.5000115740;
  const date = Math.floor(365.25 * (year + 4716) + 0.01) + Math.floor(30.60001 * (month + 1)) + day + num - 1524.5;
  return Math.floor(date);
}

export function getJulianDayByMills(date: Date, timeMills: number) {
  if (date === null || date === undefined) {
    date = new Date();
  }
  date.setTime(timeMills);
  return getJulianDay(date.getFullYear(), date.getMonth() + 1, date.getDate());
}