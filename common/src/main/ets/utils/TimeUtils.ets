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

export const HOURS_PER_DAY = 24;

export const MINUTES_PER_HOUR = 60;

export const SECONDS_PER_MINUTE = 60;

export const MILLS_PER_SECOND = 1000;

export const MILLS_PER_MINUTE = MILLS_PER_SECOND * 60;

export const MILLS_PER_HOUR = MILLS_PER_MINUTE * 60;

export const MILLS_PER_DAY = MILLS_PER_HOUR * 24;

export const MILLS_PER_WEEK = MILLS_PER_DAY * 7;

export function getMinutesByMills(date: Date, mills: number): number {
  if (date === null || date === undefined) {
    date = new Date();
  }
  date.setTime(mills);
  return date.getHours() * MINUTES_PER_HOUR + date.getMinutes();
}

/**
 * 获取当前设备所在时区与UTC时区时间差值的毫秒数
 */
export function getCurrentTimeZoneMillisecond(date: Date): number {
  return -date.getTimezoneOffset() * MILLS_PER_MINUTE;
}