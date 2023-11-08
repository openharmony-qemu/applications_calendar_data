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

import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';
import { CalendarsColumns } from '@ohos/datastructure/src/main/ets/calendars/CalendarsColumns';
import { ColorsColumns } from '@ohos/datastructure/src/main/ets/colors/ColorsColumns';
import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';
import { AttendeesColumns } from '@ohos/datastructure/src/main/ets/attendees/AttendeesColumns';
import { CalendarAlertsColumns } from '@ohos/datastructure/src/main/ets/calendaralerts/CalendarAlertsColumns';
import { CalendarCacheColumns } from '@ohos/datastructure/src/main/ets/calendarcache/CalendarCacheColumns';
import { EventsRawTimesColumns } from '@ohos/datastructure/src/main/ets/eventsrawtimes/EventsRawTimesColumns';
import {
  ExtendCalendarEventColumns
} from '@ohos/datastructure/src/main/ets/extendcalendarevent/ExtendCalendarEventColumns';
import {
  ExtendedPropertiesColumns
} from '@ohos/datastructure/src/main/ets/extendedproperties/ExtendedPropertiesColumns';
import { SyncStateColumns } from '@ohos/datastructure/src/main/ets/syncstate/SyncStateColumns';
import { MapAddressHistoryColumns } from '@ohos/datastructure/src/main/ets/location/MapAddressHistoryColumns';
import { SyncStateMetadataColumns } from '@ohos/datastructure/src/main/ets/syncstate/SyncStateMetadataColumns';
import { CalendarMetaDataColumns } from '@ohos/datastructure/src/main/ets/calendarmetadata/CalendarMetaDataColumns';
import { QUERY_START } from '@ohos/common/src/main/ets/utils/UrlUtils';
import { Log } from '@ohos/common/src/main/ets/utils/Log';

const DATA_SHARE_PREFIX: string = "datashare:///calendardata";

const EVENTS_PATH: string = "Events";

const CALENDARS_PATH: string = "Calendars";

const ATTENDEES_PATH: string = "Attendees";

const CALENDAR_ALERTS_PATH: string = "CalendarAlerts";

const CALENDAR_CACHE_PATH: string = "CalendarCache";

const CALENDAR_METADATA_PATH: string = "CalendarMetaData";

const COLORS_PATH: string = "Colors";

const EVENTS_RAW_TIME_PATH: string = "EventsRawTimes";

const EXTEND_CALENDAR_EVENT_PATH: string = "ExtendCalendarEvent";

const EXTENDED_PROPERTIES_PATH: string = "ExtendedProperties";

export const INSTANCES_PATH: string = "Instances";

const MAP_ADDRESS_HISTORY_PATH: string = "map_address_history";

const REMINDERS_PATH: string = "Reminders";

const SYNC_STATE_PATH: string = "_sync_state";

const SYNC_STATE_METADATA_PATH: string = "_sync_state_metadata";

export const URI_EVENTS: string = `${DATA_SHARE_PREFIX}/${EVENTS_PATH}`;

const TAG = "CalendarUriHelper";

/**
 * transfer the user input uri to the specific table
 *
 * @param uri the user input uri
 * @return the specific table
 */
export default function getTableByUri(uri: string): string {
  Log.log(TAG, 'getTableByUri uri: ' + uri);
  let path = getPathByUri(uri);
  let tablePathName = getTablePathNameByPath(path);
  return getTableNameByTablePath(tablePathName);
}

/**
 * transfer the table's path to the specific table name
 *
 * @param table's path that is got from user input uri
 * @return the specific table name
 */
function getTableNameByTablePath(tablePathName: string): string {
  switch (tablePathName) {
    case EVENTS_PATH:
      return EventColumns.TABLE_NAME;
    case CALENDARS_PATH:
      return CalendarsColumns.TABLE_NAME;
    case ATTENDEES_PATH:
      return AttendeesColumns.TABLE_NAME;
    case CALENDAR_ALERTS_PATH:
      return CalendarAlertsColumns.TABLE_NAME;
    case CALENDAR_CACHE_PATH:
      return CalendarCacheColumns.TABLE_NAME;
    case CALENDAR_METADATA_PATH:
      return CalendarMetaDataColumns.TABLE_NAME;
    case COLORS_PATH:
      return ColorsColumns.TABLE_NAME;
    case EVENTS_RAW_TIME_PATH:
      return EventsRawTimesColumns.TABLE_NAME;
    case EXTEND_CALENDAR_EVENT_PATH:
      return ExtendCalendarEventColumns.TABLE_NAME;
    case EXTENDED_PROPERTIES_PATH:
      return ExtendedPropertiesColumns.TABLE_NAME;
    case INSTANCES_PATH:
      return InstancesColumns.TABLE_NAME;
    case MAP_ADDRESS_HISTORY_PATH:
      return MapAddressHistoryColumns.TABLE_NAME;
    case REMINDERS_PATH:
      return RemindersColumns.TABLE_NAME;
    case SYNC_STATE_PATH:
      return SyncStateColumns.TABLE_NAME;
    case SYNC_STATE_METADATA_PATH:
      return SyncStateMetadataColumns.TABLE_NAME;
    default:
      Log.log(TAG, 'getTablePathByTableName run in default case!');
      return "";
  }
}

/**
 * transfer the user input uri to the specific resource path
 *
 * @param table's path that is got from user input uri
 * @return the resource path
 */
function getPathByUri(uri: string): string {
  // delete dataShare's prefix
  if (uri.startsWith(DATA_SHARE_PREFIX)) {
    uri = uri.split(DATA_SHARE_PREFIX).join("");
  }

  let endIndex = uri.indexOf(QUERY_START);
  const totalLength = uri.length;
  if (endIndex === -1 && totalLength > 0) {
    return uri;
  }

  // in case of uri containing query condition like Instance's uri
  if (endIndex < 1 || endIndex >= totalLength) {
    return '';
  }
  const path = uri.substring(0, endIndex);
  if (path === null || path === undefined || path.length < 1) {
    return '';
  }
  return path;
}

/**
 * transfer uri without prefix to the table's path
 *
 * @param user input uri without prefix
 * @return the table path name
 */
function getTablePathNameByPath(path: string): string {
  const array = path.split("/");
  if (array === null || array === undefined || array.length < 1) {
    return '';
  }
  return array[1];
}
