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

import data_rdb from '@ohos.data.relationalStore';

/**
 * 判断ValuesBucket中是否包含某Key的值
 *
 * @param values 待检查的ValuesBucket
 * @param key 待检测的key
 */
export function isContainsKey(values: data_rdb.ValuesBucket, key: string): boolean {
  if (values === null || values === undefined) {
    return false;
  }
  if (key === null || key === undefined) {
    return false;
  }
  return values[key] !== null && values[key] !== undefined;
}

/**
 * 判断ValuesBucket中是否包含一组Key中的某Key的值
 *
 * @param values 待检查的ValuesBucket
 * @param key 待检测的一组key
 */
export function isContainsOneOfKeys(values: data_rdb.ValuesBucket, keys: Array<string>): boolean {
  if (values === null || values === undefined) {
    return false;
  }
  if (keys === null || keys === undefined || keys.length === 0) {
    return false;
  }
  for (let key of keys) {
    if (isContainsKey(values, key)) {
      return true;
    }
  }
  return false;
}

/**
 * 判断ValuesBucket中是否包含一组Key中所有Key的值
 *
 * @param values 待检查的ValuesBucket
 * @param key 待检测的一组key
 */
export function isContainsAllKeys(values: data_rdb.ValuesBucket, keys: Array<string>): boolean {
  if (values === null || values === undefined) {
    return false;
  }
  if (keys === null || keys === undefined || keys.length === 0) {
    return false;
  }
  for (let key of keys) {
    if (!isContainsKey(values, key)) {
      return false;
    }
  }
  return true;
}