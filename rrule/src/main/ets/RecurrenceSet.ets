/**
 * @file Describe the file
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

import { Log } from '@ohos/common';
import { isEmptyStr } from '@ohos/common/src/main/ets/utils/TextUtils';
import { Frequency } from './Constants';
import { Recurrence } from './Recurrence';

// 多个重复规则时，以换行符分隔
const RULE_SEPARATOR: string = '\n';

// 多个rDate或exDate时，以英文逗号分隔
const DATE_SEPARATOR: string = ',';

const TAG: string = 'RecurrenceSet';

/**
 * the recurrence rule structure
 *
 * @since 2022-05-28
 */
export class RecurrenceSet {
  // 数据库原始数据
  public rRuleStr: string = '';
  public rDateStr: string = '';
  public exRuleStr: string = '';
  public exDateStr: string = '';
  // 解析后的循环规则数据
  public rules: Recurrence[] = [];
  public dates: string[] = [];
  public exRules: Recurrence[] = [];
  public exDates: string[] = [];

  constructor(rRule: string, rDate: string, exRule: string, exDate: string) {
    this.rRuleStr = rRule;
    this.rDateStr = rDate;
    this.exRuleStr = exRule;
    this.exDateStr = exDate;
  }

  /**
   * 是否含重复规则
   *
   * @return true 含重复规则 false 不含重复规则
   */
  public hasRecurrence(): boolean {
    return !isEmptyStr(this.rRuleStr) || !isEmptyStr(this.rDateStr);
  }

  public parseAll() {
    this.rules = parseRules(this.rRuleStr);
    this.dates = parseDates(this.rDateStr);
    this.exRules = parseRules(this.exRuleStr);
    this.exDates = parseDates(this.exDateStr);
  }

  public formatAll() {
    this.rRuleStr = formatRules(this.rules);
    this.rDateStr = formatDates(this.dates);
    this.exRuleStr = formatRules(this.exRules);
    this.exDateStr = formatDates(this.exDates);
  }

  public toLogString(): string {
    return `rule=${this.rRuleStr}, rdate=${this.rDateStr}, exRule=${this.exRuleStr}, exDate=${this.exDateStr}`;
  }
}

function parseRules(ruleStr: string): Recurrence[] {
  const result: Recurrence[] = [];
  if (isEmptyStr(ruleStr)) {
    return result;
  }
  const ruleArray: string[] = ruleStr.split(RULE_SEPARATOR);
  if (!ruleArray || (ruleArray.length <= 0)) {
    return result;
  }
  ruleArray.forEach((rule: string) => {
    if (isEmptyStr(rule)) {
      return;
    }
    const recurrence: Recurrence = Recurrence.parse(rule);
    if (recurrence.freq === Frequency.NONE) {
      Log.warn(TAG, `freq can not be NONE`);
      return;
    }
    result.push(recurrence);
  });
  return result;
}

function parseDates(dateStr: string): string[] {
  const result: string[] = [];
  if (isEmptyStr(dateStr)) {
    return result;
  }
  const dateArray: string[] = dateStr.split(DATE_SEPARATOR);
  if (!dateArray || (dateArray.length <= 0)) {
    return result;
  }
  dateArray.forEach((date: string) => {
    if (isEmptyStr(date)) {
      return;
    }
    result.push(date);
  });
  return result;
}

function formatRules(rules: Recurrence[]): string {
  return '';
}

function formatDates(dates: string[]): string {
  return '';
}