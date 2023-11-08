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

interface CalendarMetaDataColumnsType {
  TABLE_NAME: string,
  ID: string,
  LOCAL_TIME_ZONE: string,
  MIN_INSTANCE: string,
  MAX_INSTANCE: string,
}

/**
 * the const of table CalendarMetaData
 *
 * @since 2022-06-01
 */
export const CalendarMetaDataColumns: CalendarMetaDataColumnsType = {
  TABLE_NAME: 'CalendarMetaData',
  ID: '_id',
  LOCAL_TIME_ZONE: 'localTimeZone',
  MIN_INSTANCE: 'minInstance',
  MAX_INSTANCE: 'maxInstance'
}