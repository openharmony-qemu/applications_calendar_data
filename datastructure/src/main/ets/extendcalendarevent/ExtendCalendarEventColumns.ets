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

interface extendCalendarEventColumnsType {
  TABLE_NAME: string,
  ID: string,
  HWEXT_EVENT_ID: string,
  HWEXT_TYPE: string,
  HWEXT_APP_URI: string,
  HWEXT_APP_NAME: string,
  HWEXT_ACTION: string,
  HWEXT_METHOD: string,
  HWEXT_SUPPORT_MIN_VERSION: string,
  HWEXT_STATUS: string,
  HWEXT_DESCRIPTION: string,
}

/**
 * the const of table ExtendCalendarEvent
 *
 * @since 2022-09-08
 */
export const ExtendCalendarEventColumns: extendCalendarEventColumnsType = {
  TABLE_NAME: 'ExtendCalendarEvent',
  ID: 'id',
  HWEXT_EVENT_ID: 'hwext_event_id',
  HWEXT_TYPE: 'hwext_type',
  HWEXT_APP_URI: 'hwext_app_uri',
  HWEXT_APP_NAME: 'hwext_app_name',
  HWEXT_ACTION: 'hwext_action',
  HWEXT_METHOD: 'hwext_method',
  HWEXT_SUPPORT_MIN_VERSION: 'hwext_support_min_version',
  HWEXT_STATUS: 'hwext_status',
  HWEXT_DESCRIPTION: 'hwext_description',
}