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

interface eventsRawTimesColumnsType {
  TABLE_NAME: string,
  ID: string,
  EVENT_ID: string,
  DT_START_2445: string,
  DT_END_2445: string,
  ORIGINAL_INSTANCE_TIME2445: string,
  LAST_DATE2445: string,
}

/**
 * the const of table EventsRawTimes
 *
 * @since 2022-09-08
 */
export const EventsRawTimesColumns: eventsRawTimesColumnsType = {
  TABLE_NAME: 'EventsRawTimes',
  ID: '_id',
  EVENT_ID: 'event_id',
  DT_START_2445: 'dtstart2445',
  DT_END_2445: 'dtend2445',
  ORIGINAL_INSTANCE_TIME2445: 'originalInstanceTime2445',
  LAST_DATE2445: 'lastDate2445',
}