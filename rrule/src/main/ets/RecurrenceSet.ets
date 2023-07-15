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
 * the recurrence rule structure
 *
 * @since 2022-05-28
 */
export class RecurrenceSet {
  rRule: string;
  rDate: string;
  exRule: string;
  exDate: string;

  constructor(rRule: string, rDate: string, exRule: string, exDate: string) {
  }

  /**
   * 是否含重复规则
   *
   * @return true 含重复规则 false 不含重复规则
   */
  public hasRecurrence(): boolean {
    return false;
  }
}