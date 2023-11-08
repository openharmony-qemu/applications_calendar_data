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

interface AttendeesColumnsType {
  TABLE_NAME: string;
  ID: string;
  EVENT_ID: string;
  ATTENDEE_NAME: string;
  ATTENDEE_EMAIL: string;
  ATTENDEE_STATUS: string;
  ATTENDEE_RELATIONSHIP: string;
  ATTENDEE_TYPE: string;
  ATTENDEE_IDENTITY: string;
  ATTENDEE_ID_NAMESPACE: string;
  CREATOR: string;
}

/**
 * the const of table Attendees
 *
 * @since 2022-09-08
 */
export const AttendeesColumns: AttendeesColumnsType = {
  TABLE_NAME: 'Attendees',
  ID: '_id',
  EVENT_ID: 'event_id',
  ATTENDEE_NAME: 'attendeeName',
  ATTENDEE_EMAIL: 'attendeeEmail',
  ATTENDEE_STATUS: 'attendeeStatus',
  ATTENDEE_RELATIONSHIP: 'attendeeRelationship',
  ATTENDEE_TYPE: 'attendeeType',
  ATTENDEE_IDENTITY: 'attendeeIdentity',
  ATTENDEE_ID_NAMESPACE: 'attendeeIdNamespace',
  CREATOR: Constants.CREATOR,
}