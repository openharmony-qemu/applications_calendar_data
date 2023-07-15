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

import dataSharePredicates from '@ohos.data.dataSharePredicates';
import DataShareResultSet from '@ohos.data.DataShareResultSet';

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { getBundleNameByUri } from '@ohos/common/src/main/ets/utils/UrlUtils';

import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { Events } from '@ohos/datastructure/src/main/ets/events/Events';
import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';
import { parseIndexes, EventIndexes } from '@ohos/datastructure/src/main/ets/events/EventIndexes';
import { parseEvents } from '@ohos/datastructure/src/main/ets/events/EventParser';

import { initValueCreator, initPredicateCreator, deleteValueCreator } from '../DatabaseProcessorHelper';
import { DefaultProcessor } from '../DefaultProcessor';
import { ErrorCode } from '../../constants/ErrorCode';

const TAG = "RemindersProcessor";

/**
 * the RemindersProcessor table processor
 *
 * @since 2022-10-17
 */
export class RemindersProcessor extends DefaultProcessor {
  async insertByHighAuthority(rdbStore, uri: string, values, callback) {
    const callerName = getBundleNameByUri(uri);
    initValueCreator(values, callerName);
    const isEventExist = await isEventSameWithReminderId(rdbStore, values);
    if (isEventExist) {
      this.doInsert(rdbStore, uri, values, callback);
    } else {
      Log.warn(TAG, 'not support insert operation');
      const err = {
        code: ErrorCode.UN_SUPPORT_OPERATION,
        name: 'UnSupportedOperationException',
        message: 'The calling application cannot insert an reminder without its own event'
      };
      callback(err, -1);
    }
  }

  async insertByLowAuthority(rdbStore, uri: string, values, callback) {
    const callerName = getBundleNameByUri(uri);
    initValueCreator(values, callerName);
    const isEventCreatorExist = await isEventSameWithReminderCreator(rdbStore, values);
    if (isEventCreatorExist) {
      this.doInsert(rdbStore, uri, values, callback);
    } else {
      Log.warn(TAG, 'not support insert operation');
      const err = {
        code: ErrorCode.UN_SUPPORT_OPERATION,
        name: 'UnSupportedOperationException',
        message: 'The calling application cannot insert an reminder with different creator from event'
      };
      callback(err, -1);
    }
  }

  async deleteByLowAuthority(rdbStore, uri: string, predicates, callback) {
    const callerName = getBundleNameByUri(uri);
    initPredicateCreator(predicates, callerName);
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  async updateByHighAuthority(rdbStore, uri: string, values, predicates, callback) {
    deleteValueCreator(values);
    this.doUpdate(rdbStore, uri, values, predicates, callback)
  }

  async updateByLowAuthority(rdbStore, uri: string, values, predicates, callback) {
    const callerName = getBundleNameByUri(uri);
    deleteValueCreator(values);
    initPredicateCreator(predicates, callerName);
    this.doUpdate(rdbStore, uri, values, predicates, callback)
  }

  async queryByLowAuthority(rdbStore, uri: string, columns: Array<string>, predicates, callback) {
    const callerName = getBundleNameByUri(uri);
    initPredicateCreator(predicates, callerName);
    this.doQuery(rdbStore, uri, columns, predicates, callback);
  }
}
/**
 * 检查待插入的 reminder 与 event 表中相同 event_id 的元组是否拥有相同的 creator
 * @param rdbStore rdb数据库
 * @param values 插入操作的数据
 * @return true 相同 false 不相同
 */
async function isEventSameWithReminderCreator(rdbStore, values): Promise<boolean> {
  Log.debug(TAG, 'isEventSameWithReminderCreator start');
  const reminderCreator = values[RemindersColumns.CREATOR];
  let resultSet = await queryEventIdAndCreatorByReminder(rdbStore, values);
  if (resultSet === null || resultSet === undefined) {
    return false;
  }
  const eventIndexes: EventIndexes = parseIndexes(resultSet);
  if (resultSet.goToFirstRow()) {
    let events: Events = parseEvents(resultSet, eventIndexes);
    if (events === null || events === undefined) {
      return false;
    }
    if (events.creator === reminderCreator) {
      return true;
    }
  }
  return false;
}

/**
 * 检查待插入的 reminder 与 event 表中是否存在相同 event_id 的元组
 * @param rdbStore rdb数据库
 * @param values 插入操作的数据
 * @return true 相同 false 不相同
 */
async function isEventSameWithReminderId(rdbStore, values): Promise<boolean> {
  Log.debug(TAG, 'isEventSameWithReminderId start');
  let resultSet = await queryEventIdAndCreatorByReminder(rdbStore, values);
  if (resultSet === null || resultSet === undefined) {
    return false;
  }
  if (resultSet.rowCount > 0) {
    return true;
  }
  return false;
}

/**
 * 查询待插入的 reminder 数据中 event_id 与 event 表相同的结果
 * @param rdbStore rdb数据库
 * @param values 插入操作的数据
 * @return DataShareResultSet
 */
async function queryEventIdAndCreatorByReminder(rdbStore, values): Promise<DataShareResultSet> {
  const eventId = values[RemindersColumns.EVENT_ID];
  const columns = [EventColumns.ID, EventColumns.CREATOR];
  let predicates = new dataSharePredicates.DataSharePredicates();
  predicates.equalTo(EventColumns.ID, eventId);
  let resultSet: DataShareResultSet;
  try {
    resultSet = await rdbStore.query(EventColumns.TABLE_NAME, predicates, columns);
  } catch (err) {
    Log.error(TAG, 'Event query data error');
  }
  return resultSet;
}