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

import { CustomTime, FormatTime, Log } from '@ohos/common';

const TAG: string = 'DateExpandProcessor';

/**
 * 日期扩展处理器
 */
class DateExpandProcessor {
  public rangeBegin: number;

  public rangeEnd: number;

  public timeZone: string;

  public count: number = 0;

  public until: number = Number.MAX_VALUE;

  public mCustomTime: CustomTime = new CustomTime();

  public mFormatTime: FormatTime = new FormatTime();

  constructor(begin: number, end: number, timeZone: string) {
    this.rangeBegin = begin;
    this.rangeEnd = end;
    this.timeZone = timeZone;
    this.mCustomTime.setTimeZone(timeZone);
  }

  public expand(rDateStr: string, outDates: number[]) {
    if (!outDates) {
      Log.error(TAG, `expand get invalid params`);
      return;
    }
    const isParseSuccess: boolean = this.mFormatTime.parse(rDateStr, this.mCustomTime);
    if (!isParseSuccess) {
      Log.warn(TAG, `expand parse failed: ${rDateStr}`);
      return;
    }
    const rDate: number = this.mCustomTime.getTimeInMills();
    if ((rDate < this.rangeBegin) || (rDate >= this.rangeEnd)) {
      Log.warn(TAG, `expand out of range: ${this.rangeBegin}-${this.rangeEnd}`);
      return;
    }
    outDates.push(rDate);
  }

  public exclude(exDateStr: string, outDates: number[]) {
    if (!outDates) {
      Log.error(TAG, `exclude get invalid params`);
      return;
    }
    const isParseSuccess: boolean = this.mFormatTime.parse(exDateStr, this.mCustomTime);
    if (!isParseSuccess) {
      Log.warn(TAG, `exclude parse failed: ${exDateStr}`);
      return;
    }
    const exDate: number = this.mCustomTime.getTimeInMills();
    if ((exDate < this.rangeBegin) || (exDate >= this.rangeEnd)) {
      Log.warn(TAG, `exclude out of range: ${this.rangeBegin}-${this.rangeEnd}`);
      return;
    }
    const index: number = outDates.indexOf(exDate);
    if (index >= 0 && (index < outDates.length)) {
      outDates.splice(index, 1);
    }
  }
}

export {
  DateExpandProcessor
}