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

interface CalendarAlertStateType {
  STATE_SCHEDULED: number;
  STATE_FIRED: number;
  STATE_DISMISSED: number;
}

/**
 * the type of CalendarState
 *
 * @since 2022-09-13
 */
export const CalendarAlertState: CalendarAlertStateType = {
  /**
   * An alert begins in this state when it is first created.
   */
  STATE_SCHEDULED: 0,
  /**
   * After a notification for an alert has been created it should be
   * updated to fired.
   */
  STATE_FIRED: 1,
  /**
   * Once the user has dismissed the notification the alert's state should
   * be set to dismissed so it is not fired again.
   */
  STATE_DISMISSED: 2,
}