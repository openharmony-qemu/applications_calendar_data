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

interface CommonEventConstantsType {
  CHECK_NEXT_ALARM: string;
  EVENT_REMINDER: string;
  DATA_CHANGED: string;
}

/**
 * the const of CommonEvent
 *
 * @since 2022-10-08
 */
export const CommonEventConstants: CommonEventConstantsType = {
  CHECK_NEXT_ALARM: 'calendardata.CHECK_NEXT_ALARM',
  EVENT_REMINDER: 'calendardata.EVENT_REMINDER',
  DATA_CHANGED: 'calendardata.DATA_CHANGED',
}