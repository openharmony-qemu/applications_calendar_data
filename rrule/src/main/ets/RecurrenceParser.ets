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

import { Log } from '@ohos/common/src/main/ets/utils/Log';

import { Recurrence } from './Recurrence';
import { Week } from './Constants';
import ParseByHour from './ruleparse/ParseByHour';
import ParseByMinute from './ruleparse/ParseByMinute';
import ParseByMonth from './ruleparse/ParseByMonth';
import ParseByMonthDay from './ruleparse/ParseByMonthDay';
import ParseBySecond from './ruleparse/ParseBySecond';
import ParseBySetPos from './ruleparse/ParseBySetPos';
import ParseByWeek from './ruleparse/ParseByWeek';
import ParseByWeekDay from './ruleparse/ParseByWeekDay';
import ParseByYearDay from './ruleparse/ParseByYearDay';
import ParseCount from './ruleparse/ParseCount';
import ParseFreq from './ruleparse/ParseFreq';
import ParseInterval from './ruleparse/ParseInterval';
import ParseUntil from './ruleparse/ParseUntil';
import ParseWkSt from './ruleparse/ParseWkSt';
import PartParser from './ruleparse/PartParser';
import { isEmptyStr } from '@ohos/common/src/main/ets/utils/TextUtils';

const FLAG_FREQ: number = 1 << 0;
const FLAG_UNTIL: number = 1 << 1;
const FLAG_COUNT: number = 1 << 2;
const FLAG_INTERVAL: number = 1 << 3;
const FLAG_BY_SECOND: number = 1 << 4;
const FLAG_BY_MINUTE: number = 1 << 5;
const FLAG_BY_HOUR: number = 1 << 6;
const FLAG_BY_WEEK_DAY: number = 1 << 7;
const FLAG_BY_MONTH_DAY: number = 1 << 8;
const FLAG_BY_YEAR_DAY: number = 1 << 9;
const FLAG_BY_WEEK_NUM: number = 1 << 10;
const FLAG_BY_MONTH: number = 1 << 11;
const FLAG_BY_SET_POSITION: number = 1 << 12;
const FLAG_WEEK_START: number = 1 << 13;

const TAG: string = 'RecurrenceParser';

/**
 * 按字段key获取对应星期x
 */
const WEEK_MAP: Record<string, Week> = {
  'SU': Week.SUN,
  'MO': Week.MON,
  'TU': Week.TUE,
  'WE': Week.WED,
  'TH': Week.THUR,
  'FR': Week.FRI,
  'SA': Week.SAT
};

/**
 * 按字段key索引对应的value解析器
 */
const PART_PARSER_MAP: Record<string, PartParser> = {
  'FREQ': new ParseFreq(),
  'UNTIL': new ParseUntil(),
  'COUNT': new ParseCount(),
  'INTERVAL': new ParseInterval(),
  'BYSECOND': new ParseBySecond(),
  'BYMINUTE': new ParseByMinute(),
  'BYHOUR': new ParseByHour(),
  'BYDAY': new ParseByWeekDay(),
  'BYMONTHDAY': new ParseByMonthDay(),
  'BYYEARDAY': new ParseByYearDay(),
  'BYWEEKNO': new ParseByWeek(),
  'BYMONTH': new ParseByMonth(),
  'BYSETPOS': new ParseBySetPos(),
  'WKST': new ParseWkSt()
};

function parsePartByKey(key: string, value: string, recurrence: Recurrence) {
  if (!key) {
    Log.error(TAG, `parsePartByKey get invalid key`);
    return;
  }

  // 根据key索引到对应的解析器，传入value和recurrence进行解析
  PART_PARSER_MAP[key]?.parsePart(value, recurrence);
}

function parseNumber(value: string, minValue: number, maxValue: number, allowZero: boolean = true): number | null {
  if (isEmptyStr(value)) {
    Log.warn(TAG, `parseNumber by empty str`);
    return null;
  }
  try {
    if (value.startsWith('+')) {
      value = value.substring(1);
    }
    const num: number = Number.parseInt(value, 10);
    if ((!allowZero) && (num === 0)) {
      return null;
    }
    if ((num >= minValue) && (num <= maxValue)) {
      return num;
    }
  } catch (e) {
    Log.error(TAG, `parseNumber get Err: ${e?.message}`);
  }
  return null;
}

function parseNumberList(value: string, minValue: number, maxValue: number, allowZero: boolean = true): number[] {
  const numList: number[] = [];
  if (isEmptyStr(value)) {
    Log.warn(TAG, `parseNumberList by empty str`);
    return numList;
  }
  try {
    if (value.indexOf(',') < 0) {
      const num: number | null = parseNumber(value, minValue, maxValue, allowZero);
      if (num !== null) {
        numList.push(num);
      }
    } else {
      const strArray: string[] = value.split(',');
      strArray.forEach((str: string) => {
        const num: number | null = parseNumber(str, minValue, maxValue, allowZero);
        if (num !== null) {
          numList.push(num);
        }
      });
    }
  } catch (e) {
    Log.error(TAG, `parseNumberList get Err: ${e?.message}`);
  }
  return numList;
}

export {
  parsePartByKey,
  parseNumber,
  parseNumberList,
  WEEK_MAP,
  FLAG_FREQ,
  FLAG_UNTIL,
  FLAG_COUNT,
  FLAG_INTERVAL,
  FLAG_BY_SECOND,
  FLAG_BY_MINUTE,
  FLAG_BY_HOUR,
  FLAG_BY_WEEK_DAY,
  FLAG_BY_MONTH_DAY,
  FLAG_BY_YEAR_DAY,
  FLAG_BY_WEEK_NUM,
  FLAG_BY_MONTH,
  FLAG_BY_SET_POSITION,
  FLAG_WEEK_START
};