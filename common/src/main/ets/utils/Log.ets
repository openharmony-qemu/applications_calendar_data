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

const TAG = 'CalendarData';

/**
 * Global Log class
 *
 * @since 2022-04-13
 */
export class Log {
  public static log(classTag: string, msg: string) {
    console.log(TAG + "--" + classTag + ":" + msg);
  }

  public static debug(classTag: string, msg: string) {
    console.debug(TAG + "--" + classTag + ":" + msg);
  }

  public static info(classTag: string, msg: string) {
    console.info(TAG + "--" + classTag + ":" + msg);
  }

  public static warn(classTag: string, msg: string) {
    console.warn(TAG + "--" + classTag + ":" + msg);
  }

  public static error(classTag: string, msg: string) {
    console.error(TAG + "--" + classTag + ":" + msg);
  }

  public static stringify(data: object): string {
    return JSON.stringify(data, null, 4);
  }
}
