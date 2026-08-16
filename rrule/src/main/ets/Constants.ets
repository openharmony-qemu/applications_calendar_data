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

export enum Frequency {
  NONE = 0,

  SECONDLY = 1,

  MINUTELY = 2,

  HOURLY = 3,

  DAILY = 4,

  WEEKLY = 5,

  MONTHLY = 6,

  YEARLY = 7
}

export enum Week {
  UNDEFINED = 0,

  SUN = 1,

  MON = 2,

  TUE = 3,

  WED = 4,

  THUR = 5,

  FRI = 6,

  SAT = 7
}

/**
 * 用于承载周期日程扩展算法的执行结果
 */
export class ExpandFlag {
  public isInvalidParam: boolean = false;
  public isBreakByRule: boolean = false;
}