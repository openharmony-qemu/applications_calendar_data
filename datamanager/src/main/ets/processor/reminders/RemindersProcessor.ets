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

import data_rdb from '@ohos.data.relationalStore';
import dataSharePredicates from '@ohos.data.dataSharePredicates';

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { getBundleNameByUri } from '@ohos/common/src/main/ets/utils/UrlUtils';
import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';

import { deleteValueCreator, initPredicateCreator, initValueCreator } from '../DatabaseProcessorHelper';
import {
  notifyProviderChange,
  OPERATION_DELETE,
  OPERATION_INSERT,
  OPERATION_UPDATE
} from '../../commonevents/notify/ProviderChangeNotifier';
import {
  DefaultProcessor,
  DELETE_OPERATION_NAME,
  INSERT_OPERATION_NAME,
  UPDATE_OPERATION_NAME
} from '../DefaultProcessor';
import { ErrorCode } from '../../constants/ErrorCode';
import getTableByUri from '../../utils/CalendarUriHelper';
import { BusinessError } from '@ohos.base';
import { Reminders } from '@ohos/datastructure/src/main/ets/reminders/Reminders';
import { ValueType } from '@ohos.data.ValuesBucket';
import { RdbStoreHelper } from '../../utils/RdbStoreHelper';
import { AlertsObserverManager } from '../alerts/observer/AlertsObserverManager';
import { queryEventsById } from '../events/EventsProcessor';
import { util } from '@kit.ArkTS';
import { hasNoError } from '@ohos/common';
import { EventIndexes, Events, parseEventByIndex, parseEvents, parseIndexes } from '@ohos/datastructure';
import { queryReminders } from '../../commonevents/TablesManager/RemindersManager';

const TAG = 'RemindersProcessor';

const REMIND_QUERY_SQL = `SELECT ${EventColumns.TABLE_NAME}.${EventColumns.ID},` +
  `${RemindersColumns.TABLE_NAME}.${RemindersColumns.REMINDER_UUID},` +
  `${RemindersColumns.TABLE_NAME}.${RemindersColumns.EVENT_UUID} FROM ${EventColumns.TABLE_NAME}
  INNER JOIN ${RemindersColumns.TABLE_NAME} ON (${EventColumns.TABLE_NAME}.${EventColumns.UUID}=` +
  `${RemindersColumns.TABLE_NAME}.${RemindersColumns.EVENT_UUID}) ` +
  `WHERE ${RemindersColumns.EVENT_UUID} is not null`;

/**
 * the RemindersProcessor table processor
 *
 * @since 2022-10-17
 */
export class RemindersProcessor extends DefaultProcessor {
  public constructor(isFromMigrate?: boolean) {
    super(isFromMigrate);
  }

  async insertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string,
                              values: data_rdb.ValuesBucket, callback: Function) {
    if (!this.isFromMigrate) {
      const callerName = getBundleNameByUri(uri);
      initValueCreator(values, callerName);
    }
    const isEventExist = await isEventSameWithReminderId(rdbStore, values);
    if (isEventExist) {
      await fillReminderUuid(values, rdbStore);
      this.doInsert(rdbStore, uri, values, callback);
    } else {
      Log.warn(TAG, 'not support insert operation');
      const err: BusinessError = {
        code: ErrorCode.UN_SUPPORT_OPERATION,
        name: 'UnSupportedOperationException',
        message: 'The calling application cannot insert an reminder without its own event'
      };
      callback(err, -1);
    }
  }

  async insertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string,
                             values: data_rdb.ValuesBucket, callback: Function) {
    if (!this.isFromMigrate) {
      const callerName = getBundleNameByUri(uri);
      initValueCreator(values, callerName);
    }
    const isEventCreatorExist = await isEventSameWithReminderCreator(rdbStore, values);
    if (isEventCreatorExist) {
      await fillReminderUuid(values, rdbStore);
      this.doInsert(rdbStore, uri, values, callback);
    } else {
      Log.warn(TAG, 'not support insert operation');
      const err: BusinessError = {
        code: ErrorCode.UN_SUPPORT_OPERATION,
        name: 'UnSupportedOperationException',
        message: 'The calling application cannot insert an reminder with different creator from event'
      };
      callback(err, -1);
    }
  }

  async deleteByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string,
                             predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  async deleteByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string,
                             predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    initPredicateCreator(predicates, callerName);
    this.doDelete(rdbStore, uri, predicates, callback);
  }

  async updateByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket,
                              predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    values = deleteValueCreator(values);
    this.doUpdate(rdbStore, uri, values, predicates, callback)
  }

  async updateByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket,
                             predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const callerName = getBundleNameByUri(uri);
    values = deleteValueCreator(values);
    initPredicateCreator(predicates, callerName);
    this.doUpdate(rdbStore, uri, values, predicates, callback)
  }

  batchInsertByHighAuthority(rdbStore: data_rdb.RdbStore, uri: string,
                             values: data_rdb.ValuesBucket[], callback: Function): void {
    this.doBatchInsert(rdbStore, uri, values, callback);
  }

  batchInsertByLowAuthority(rdbStore: data_rdb.RdbStore, uri: string,
                            values: data_rdb.ValuesBucket[], callback: Function): void {
    this.doBatchInsert(rdbStore, uri, values, callback);
  }

  /**
   * 后续提醒代理设置逻辑中，需要插入后的id，用于设置提醒后回填代理提醒id，因此不能使用rdb的batchInsert直接插入。
   * 使用for循环逐个插入，并复用单个插入。
   *
   * @param rdbStore rdb数据库，透传
   * @param uri uri，透传
   * @param values 待插入的提醒数据数组，将对齐遍历逐个插入
   * @param callback 外部callback回调，全部插入完成后调用
   * @returns void，无返回值
   */
  async doBatchInsert(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket[], callback: Function):
    Promise<void> {
    if (!values || values.length === 0) {
      Log.warn(TAG, `doBatchInsert get invalid params`);
      if (callback) {
        callback();
      }
      return;
    }
    let resultErr: BusinessError | undefined = undefined;
    let count: number = 0;
    try {
      for (let index: number = 0, size = values.length; index < size; index++) {
        await fillReminderUuid(values[index], rdbStore);
        let rowId = await this.doInsertSync(rdbStore, uri, values[index]);
        if (rowId > 0) {
          count++;
        }
      }
    } catch (err) {
      Log.error(TAG, `doBatchInsert getErr: ${err.code}, ${err.message}`);
      resultErr = err;
    }
    Log.info(TAG, `doBatchInsert end count=${count}`);
    callback(resultErr, count);
  }

  /**
   * 将异步 callback 的 doInsert 转换为 Promise 的同步阻塞式实现
   *
   * @param rdbStore rdb数据库，透传
   * @param uri uri，透传
   * @param values 待插入的数据，透传
   * @returns 插入结果，promise返回
   */
  async doInsertSync(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket): Promise<number> {
    return new Promise<number>((resolve, reject) => {
      this.doInsert(rdbStore, uri, values, (err: BusinessError, rowId: number) => {
        if (hasNoError(err)) {
          resolve(rowId);
        } else {
          reject(err);
        }
      });
    });
  }

  /**
   * 插入reminder并且发送通知
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 插入的数据
   * @param callback 回调方法
   */
  doInsert(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket, callback: Function) {
    const table = getTableByUri(uri);
    Log.warn(TAG, `insert ${table} start`);
    RdbStoreHelper.insertCallBack(rdbStore, table, values, async (err, rowId) => {
      Log.warn(TAG, `insert ${table} before callback rowId=${rowId}`);
      const reminder: Reminders = generateReminderFromValues(values, rowId);
      callback(err, rowId);
      Log.log(TAG, `insert ${table} after callback: rowId = ${rowId}`);
      if (hasNoError(err)) {
        Log.warn(TAG, `insertReminder success id=${rowId} minutes=${values[RemindersColumns.MINUTES]}`);
        if (!this.isFromMigrate) {
          notifyProviderChange(table, OPERATION_INSERT);
          AlertsObserverManager.getInstance().notifyAlertsChanges(INSERT_OPERATION_NAME, table, values);
        }
      } else {
        Log.warn(TAG, `insert get err:${err?.code}, ${err?.message}`);
      }
    });
  }

  /**
   * 删除reminder并且取消通知
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param predicates 删除条件
   * @param callback 回调方法
   */
  async doDelete(rdbStore: data_rdb.RdbStore, uri: string, predicates: dataSharePredicates.DataSharePredicates,
                 callback: Function) {
    const table = getTableByUri(uri);
    const reminders = await queryReminders(rdbStore, predicates);
    if (!reminders) {
      callback();
      Log.warn(TAG, 'doDelete: the reminders is null');
      return;
    }
    Log.warn(TAG, `delete ${table} start`);
    RdbStoreHelper.deleteCallBack(rdbStore, table, predicates, async (err, count) => {
      Log.warn(TAG, `delete ${table} before callback count=${count}`);
      callback(err, count);
      Log.log(TAG, `delete ${table} after callback: count = ` + count);

      if (hasNoError(err)) {
        Log.warn(TAG, `deleteReminder success count=${count}`);
        notifyProviderChange(table, OPERATION_DELETE);
        AlertsObserverManager.getInstance().notifyAlertsChanges(DELETE_OPERATION_NAME, table);
      } else {
        Log.warn(TAG, `delete get err:${err?.code}, ${err?.message}`);
      }
    });
  }

  /**
   * 更新reminder并且更新通知
   *
   * @param rdbStore rdb数据库
   * @param uri DataShare的uri
   * @param values 更新的数据
   * @param predicates 更新条件
   * @param callback 回调方法
   */
  async doUpdate(rdbStore: data_rdb.RdbStore, uri: string, values: data_rdb.ValuesBucket,
                 predicates: dataSharePredicates.DataSharePredicates, callback: Function) {
    const table = getTableByUri(uri);
    Log.warn(TAG, `update ${table} start`);
    RdbStoreHelper.updateCallBack(rdbStore, table, values, predicates, async (err: BusinessError, count) => {
      Log.warn(TAG, `update ${table} before callback count=${count}`);
      callback(err, count);
      if (hasNoError(err)) {
        Log.warn(TAG, `updateReminder success count=${count}`);
        notifyProviderChange(table, OPERATION_UPDATE);
        AlertsObserverManager.getInstance().notifyAlertsChanges(UPDATE_OPERATION_NAME, table, values);
      } else {
        Log.warn(TAG, `update get err:${err?.code}, ${err?.message}`);
      }
    });
  }
}
/**
 * 检查待插入的 reminder 与 event 表中相同 event_id 的元组是否拥有相同的 creator
 * @param rdbStore rdb数据库
 * @param values 插入操作的数据
 * @return true 相同 false 不相同
 */
async function isEventSameWithReminderCreator(rdbStore: data_rdb.RdbStore,
                                              values: data_rdb.ValuesBucket): Promise<boolean> {
  Log.debug(TAG, 'isEventSameWithReminderCreator start');
  const reminderCreator = values[RemindersColumns.CREATOR];
  let resultSet = await queryEventIdAndCreatorByReminder(rdbStore, values);
  if (resultSet === null || resultSet === undefined) {
    return false;
  }
  try {
    const eventIndexes: EventIndexes = parseIndexes(resultSet) as EventIndexes;
    if (resultSet.goToFirstRow()) {
      let events: Events | undefined = parseEventByIndex(resultSet, eventIndexes);
      if (events === null || events === undefined) {
        return false;
      }
      if (events.creator === reminderCreator) {
        return true;
      }
    }
  } catch (err) {
    Log.warn(TAG, `isEventSameWithReminderCreator err ${JSON.stringify(err)}`);
  } finally {
    if (resultSet) {
      resultSet.close();
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
async function isEventSameWithReminderId(rdbStore: data_rdb.RdbStore,
                                         values: data_rdb.ValuesBucket): Promise<boolean> {
  Log.debug(TAG, 'isEventSameWithReminderId start');
  let resultSet = await queryEventIdAndCreatorByReminder(rdbStore, values);
  try {
    if (resultSet === null || resultSet === undefined) {
      return false;
    }
    if (resultSet.rowCount > 0) {
      return true;
    }
  } catch (err) {
    Log.warn(TAG, `isEventSameWithReminderId err ${JSON.stringify(err)}`);
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  return false;
}

/**
 * 查询待插入的 reminder 数据中 event_id 与 event 表相同的结果
 * @param rdbStore rdb数据库
 * @param values 插入操作的数据
 * @return DataShareResultSet
 */
async function queryEventIdAndCreatorByReminder(rdbStore: data_rdb.RdbStore,
                                                values: data_rdb.ValuesBucket): Promise<data_rdb.ResultSet> {
  const eventId = values[RemindersColumns.EVENT_ID] as ValueType;
  const columns = [EventColumns.ID, EventColumns.CREATOR];
  let predicates = new dataSharePredicates.DataSharePredicates();
  predicates.equalTo(EventColumns.ID, eventId);
  let resultSet: data_rdb.ResultSet = {} as data_rdb.ResultSet;
  try {
    resultSet = await rdbStore.query(EventColumns.TABLE_NAME, predicates, columns);
  } catch (err) {
    Log.error(TAG, 'Event query data error');
  }
  return resultSet;
}

export function generateReminderFromValues(values: data_rdb.ValuesBucket, reminderId: number): Reminders {
  const reminder: Reminders = new Reminders();
  try {
    reminder.id = reminderId;
    reminder.eventId = values[RemindersColumns.EVENT_ID] as number;
    reminder.minutes = values[RemindersColumns.MINUTES] as number;
    reminder.method = values[RemindersColumns.METHOD] as number;
    reminder.creator = values[RemindersColumns.CREATOR] as string;
  } catch (e) {
    Log.error(TAG, `generateReminderFromValues get some err: ${e?.message}`);
  }
  return reminder;
}

export async function fillReminderUuid(values: data_rdb.ValuesBucket, rdbStore: data_rdb.RdbStore) {
  let eventUuid = values[RemindersColumns.EVENT_UUID];
  if (!values[RemindersColumns.EVENT_UUID]) {
    const eventId = values[RemindersColumns.EVENT_ID] as number;
    const eventInfo = await queryEventsById(rdbStore, eventId);
    if (eventInfo) {
      values[RemindersColumns.EVENT_UUID] = eventInfo.uuid;
      eventUuid = eventInfo.uuid;
    } else {
      eventUuid = util.generateRandomUUID();
      Log.warn(TAG, 'queryEventsById get undefined.');
    }
  }

  if (!values[RemindersColumns.REMINDER_UUID]) {
    values[RemindersColumns.REMINDER_UUID] =
      `${eventUuid}${values[RemindersColumns.MINUTES]}${values[RemindersColumns.METHOD]}`;
  }
}

export async function fillReminderEventUuids(rdbStore: data_rdb.RdbStore, reminders: Reminders[]): Promise<void> {
  if (!rdbStore) {
    Log.warn(TAG, 'fillReminderEventUuids get invalid rdb');
    return;
  }
  if (!reminders || reminders.length === 0) {
    Log.warn(TAG, 'fillReminderEventUuids get invalid reminders');
    return;
  }

  // 根据eventId查询eventUuid
  const eventIds: number[] = [];
  reminders.forEach((reminder: Reminders) => {
    if (!reminder) {
      return;
    }
    if (!eventIds.includes(reminder.eventId)) {
      eventIds.push(reminder.eventId);
    }
  });
  const eventUuidMap: Map<number, string> = await getEventUuidByIds(rdbStore, eventIds);

  // 将对应的eventUuid填充给Reminders对象
  reminders.forEach((reminder: Reminders) => {
    if (!reminder) {
      return;
    }
    const eventUuid = eventUuidMap.get(reminder.eventId);
    if (eventUuid && eventUuid.length > 0) {
      reminder.eventUuid = eventUuid;
    }
  });
}

async function getEventUuidByIds(rdbStore: data_rdb.RdbStore, ids: number[]): Promise<Map<number, string>> {
  const map: Map<number, string> = new Map<number, string>();
  let resultSet: data_rdb.ResultSet | null = null;
  try {
    const predicate: data_rdb.RdbPredicates = new data_rdb.RdbPredicates(EventColumns.TABLE_NAME);
    predicate.in(EventColumns.ID, ids);
    resultSet = await rdbStore.query(predicate, [EventColumns.ID, EventColumns.UUID]);
    if (!resultSet) {
      Log.warn(TAG, 'getEventUuidByIds get invalid resultSet');
      return map;
    }
    if (!resultSet.goToFirstRow()) {
      Log.warn(TAG, 'getEventUuidByIds goToFirstRow failed');
      return map;
    }
    do {
      const row = resultSet.getRow();
      const eventId: number = row[EventColumns.ID] as number;
      const uuid: string = row[EventColumns.UUID] as string;
      if (eventId && uuid) {
        map.set(eventId, uuid);
      }
    } while (resultSet.goToNextRow());
  } catch (err) {
    Log.logErrorMsg(TAG, 'getEventUuidByIds', err);
  } finally {
    if (resultSet) {
      resultSet.close();
    }
  }
  return map;
}