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

import { Constants } from '../Constants';

interface instancesColumnsType {
  TABLE_NAME: string,
  ID: string,
  EVENT_ID: string,
  BEGIN: string,
  END: string,
  START_DAY: string,
  END_DAY: string,
  START_MINUTE: string,
  END_MINUTE: string,
  CREATOR: string,
}

/**
 * the const of table Instances
 *
 * @since 2022-06-01
 */
export const InstancesColumns: instancesColumnsType = {
  TABLE_NAME: 'Instances',
  ID: '_id',
  EVENT_ID: 'event_id',
  BEGIN: 'begin',
  END: 'end',
  START_DAY: 'startDay',
  END_DAY: 'endDay',
  START_MINUTE: 'startMinute',
  END_MINUTE: 'endMinute',
  CREATOR: Constants.CREATOR,
}