
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
 
import { Log } from './Log';

const TAG = 'TextUtils';

export function isEmptyStr(str: string): boolean {
  if (str === null || str === undefined) {
    return true;
  }
  return str.length <= 0;
}

/**
 * Check whether the character string is consecutive without separators such as spaces.
 *
 * @param str the string to be check
 */
export function isUninterrupted(str: string): boolean {
  if (isEmptyStr(str)) {
    return false;
  }
  return new RegExp("/^[a-zA-z][a-zA-Z0-9]*$/").test(str);
}


/**
 * 解析字符串为数字
 *
 * @param value 待解析的字符串
 * @param defaultValue 默认值，解析失败时返回该值
 * @returns 解析后的数字值
 */
export function parseNumber(value: string, defaultValue : number = 0): number {
  let num: number = defaultValue;
  if (isEmptyStr(value)) {
    return num;
  }
  try {
    num = Number.parseInt(value);
  } catch (e) {
    Log.error(TAG, `parseNumber get Err: ${e?.message}`);
    return defaultValue;
  }
  if (Number.isNaN(num)) {
    return defaultValue;
  }
  return num;
}
