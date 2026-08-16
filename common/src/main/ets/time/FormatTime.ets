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

import { Log } from '../utils/Log';
import { CustomTime, TIME_ZONE_UTC } from './CustTime';

const TAG: string = 'FormatTime';

/**
 * 格式化的时间处理，包含解析和格式化，兼容的时间格式如下：
 * 20231108、20231108T172800
 */
export class FormatTime {
  public year: number = 0;
  public month: number = 0;
  public day: number = 0;
  public hour: number = 0;
  public minute: number = 0;
  public second: number = 0;
  public isUTC: boolean = false;
  public timeStamp: number = 0;

  public parse(timeStr: string, customTime: CustomTime): boolean {
    if ((timeStr === null) || (timeStr === undefined) || (timeStr.length < 8)) {
      return false;
    }
    const isParseSuccess: boolean = this.parseData(timeStr);
    if (!isParseSuccess || !customTime) {
      return isParseSuccess;
    }
    const originalTimeZone: string = customTime.getTimeZone();
    if ((timeStr.length > 15) && (timeStr.charAt(15) === 'Z')) {
      this.isUTC = true;
      customTime.setTimeZone(TIME_ZONE_UTC);
    }
    customTime.set(this.year, this.month, this.day, this.hour, this.minute, this.second);
    this.timeStamp = customTime.getTimeInMills();
    customTime.setTimeZone(originalTimeZone);
    return true;
  }

  private parseData(timeStr: string): boolean {
    try {
      this.year = Number.parseInt(timeStr.substring(0, 4));
      this.month = (Number.parseInt(timeStr.substring(4, 6)) + 11) % 12;
      this.day = Number.parseInt(timeStr.substring(6, 8));
      if (timeStr.indexOf('T') > 0 && timeStr.length >= 15) {
        this.hour = Number.parseInt(timeStr.substring(9, 11));
        this.minute = Number.parseInt(timeStr.substring(11, 13));
        this.second = Number.parseInt(timeStr.substring(13, 15));
      }
      return true;
    } catch (e) {
      Log.error(TAG, `parse ${timeStr} failed: ${e?.message}`);
    }
    return false;
  }

  public static format(mills: number, inDate: boolean = false, tzId: string = TIME_ZONE_UTC): string {
    if (mills === 0) {
      return '';
    }
    const customTime = new CustomTime();
    customTime.setTimeZone(tzId);
    customTime.setTime(mills);

    const year = customTime.getYear();
    const month = customTime.getMonth() + 1;
    const day = customTime.getDate();
    const dateStr: string = `${year}${month < 10 ? '0' : ''}${month}${day < 10 ? '0' : ''}${day}`;
    if (inDate) {
      return dateStr;
    }

    const isUtc = tzId === TIME_ZONE_UTC;
    const hour = customTime.getHourOfDay();
    const minute = customTime.getMinute();
    const second = customTime.getSecond();
    const timeStr: string = `${hour < 10 ? '0' : ''}${hour}${minute < 10 ? '0' : ''}${minute}` +
      `${second < 10 ? '0' : ''}${second}`;
    return `${dateStr}T${timeStr}${isUtc ? 'Z' : ''}`;
  }
}