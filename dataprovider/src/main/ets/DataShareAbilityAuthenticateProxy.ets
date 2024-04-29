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

import privacyManager, { Permissions } from '@ohos.privacyManager';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { hasNoError } from '@ohos/common/src/main/ets/utils/ErrorUtils';
import {
  BundleNameAndTokenIdFromUri,
  getBundleNameAndTokenIDByUri
} from '@ohos/common/src/main/ets/utils/UrlUtils';

import { ErrorCode } from '@ohos/datamanager/src/main/ets/constants/ErrorCode';
import delegate from './DataShareAbilityDelegate'
import data_rdb from '@ohos.data.relationalStore';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import { ValuesBucket } from '@ohos.data.ValuesBucket';

const TAG = "DataShareAbilityAuthenticateProxy";

const INSERT_BY_PROXY_OPERATION_NAME: string = 'insert';
const UPDATE_BY_PROXY_OPERATION_NAME: string = 'update';
const DELETE_BY_PROXY_OPERATION_NAME: string = 'delete';
const QUERY_BY_PROXY_OPERATION_NAME: string = 'query';

const PERMISSIONS_FLAG_HIGH: number = 2;
const PERMISSIONS_FLAG_LOW: number = 1;
const PERMISSIONS_FLAG_UNAUTHORIZED: number = -1;

const PERMISSIONS_WRITE_WHOLE_CALENDAR: Permissions = "ohos.permission.WRITE_WHOLE_CALENDAR"
const PERMISSIONS_WRITE_CALENDAR: Permissions = "ohos.permission.WRITE_CALENDAR"
const PERMISSIONS_READ_WHOLE_CALENDAR: Permissions = "ohos.permission.READ_WHOLE_CALENDAR"
const PERMISSIONS_READ_CALENDAR: Permissions = "ohos.permission.READ_CALENDAR"

const SUCCESS_COUNT: number = 1;
const FAIL_COUNT: number = 1;

/**
 * the proxy of CalendarData's DataShareAbilityDelegate, identify the high and low permissions of the app
 *
 * @since 2022-10-17
 */
class DataShareAbilityAuthenticateProxy {
  async init(): Promise<boolean> {
    Log.log(TAG, 'init start');
    let isDatabaseInitComplete = await delegate.init();
    Log.log(TAG, 'init end');
    return isDatabaseInitComplete;
  }

  async insertByProxy(uri: string, value: data_rdb.ValuesBucket | data_rdb.ValuesBucket[], permission: Permissions, callback: Function) {
    let insertDataParameter = new InsertDataParameter(value);
    insertDataParameter.operationName = INSERT_BY_PROXY_OPERATION_NAME;
    let verifyFlag = await verifyByUri(uri, insertDataParameter, PERMISSIONS_WRITE_WHOLE_CALENDAR,
      PERMISSIONS_WRITE_CALENDAR, permission, callback);
    dataOperateAfterVerify(uri, verifyFlag, insertDataParameter);
  }

  async deleteByProxy(uri: string, predicates: dataSharePredicates.DataSharePredicates, permission: Permissions, callback: Function) {
    let deleteDataParameter = new DeleteDataParameter(predicates);
    deleteDataParameter.operationName = DELETE_BY_PROXY_OPERATION_NAME;
    let verifyFlag = await verifyByUri(uri, deleteDataParameter, PERMISSIONS_WRITE_WHOLE_CALENDAR,
      PERMISSIONS_WRITE_CALENDAR, permission, callback);
    dataOperateAfterVerify(uri, verifyFlag, deleteDataParameter);
  }

  async updateByProxy(uri: string, value: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates, permission: Permissions, callback: Function) {
    let updateDataParameter = new UpdateDataParameter(value, predicates);
    updateDataParameter.operationName = UPDATE_BY_PROXY_OPERATION_NAME;
    let verifyFlag = await verifyByUri(uri, updateDataParameter, PERMISSIONS_WRITE_WHOLE_CALENDAR,
      PERMISSIONS_WRITE_CALENDAR, permission, callback);
    dataOperateAfterVerify(uri, verifyFlag, updateDataParameter);
  }

  async queryByProxy(uri: string, columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates, permission: Permissions, callback: Function) {
    let queryDataParameter = new QueryDataParameter(columns, predicates);
    queryDataParameter.operationName = QUERY_BY_PROXY_OPERATION_NAME;
    let verifyFlag = await verifyByUri(uri, queryDataParameter, PERMISSIONS_READ_WHOLE_CALENDAR,
      PERMISSIONS_READ_CALENDAR, permission, callback);
    dataOperateAfterVerify(uri, verifyFlag, queryDataParameter);
  }
}

/**
 * Verify corresponding to permissions
 *
 * @Param uri indicates user's input uri
 * @Param dataParameter indicates database operation information to be performed
 * @Param highPermission indicates high-level permission to be verified
 * @Param lowPermission indicates low-level permission to be verified
 */
async function verifyByUri(uri: string, dataParameter: DataParameter, highPermission: Permissions,
                           lowPermission: Permissions, permission: Permissions, callback: Function): Promise<number> {
  let bundleNameAndTokenIdFromUri: BundleNameAndTokenIdFromUri = getBundleNameAndTokenIDByUri(uri);

  // Verify whether tokenId has HIGH-level to use database.
  if (permission === PERMISSIONS_READ_WHOLE_CALENDAR || permission === PERMISSIONS_WRITE_WHOLE_CALENDAR) {
    // Encapsulate the callback function of an object to add Permission Used Record
    dataParameter.callback = (err: BusinessError, rowId: number) => {
      callback(err, rowId);
      addPermissionUsedRecordInCallBack(err, bundleNameAndTokenIdFromUri.tokenId, highPermission);
    }
    // return high-level
    return PERMISSIONS_FLAG_HIGH;
  }

  // Verify whether tokenId has LOW-level to use database.
  if (permission === PERMISSIONS_READ_CALENDAR || permission === PERMISSIONS_WRITE_CALENDAR) {
    // Encapsulate the callback function of an object to add Permission Used Record
    dataParameter.callback = (err: BusinessError, rowId: number) => {
      callback(err, rowId);
      addPermissionUsedRecordInCallBack(err, bundleNameAndTokenIdFromUri.tokenId, lowPermission);
    }
    // return low-level
    return PERMISSIONS_FLAG_LOW;
  }
  return PERMISSIONS_FLAG_UNAUTHORIZED;
}

/**
 * Perform database operations corresponding to permissions
 *
 * @Param uri indicates user's input uri
 * @Param verifyFlag indicates the Check flag returned by permission check
 * @Param dataParameter indicates database operation information to be performed
 */
function dataOperateAfterVerify(uri: string, verifyFlag: number, dataParameter: DataParameter) {
  if (verifyFlag === PERMISSIONS_FLAG_HIGH) {
    dataOperateSelectorByHighAuthority(uri, dataParameter);
  } else if (verifyFlag === PERMISSIONS_FLAG_LOW) {
    dataOperateSelectorByLowAuthority(uri, dataParameter);
  } else {
    // callback error with information
    const err: BusinessError = {
      code: ErrorCode.ILLEGAL_ARGUMENT_ERROR,
      name: 'AuthenticateException',
      message: 'Caller App does not have permission to read'
    };
    dataParameter.callback(err, PERMISSIONS_FLAG_UNAUTHORIZED);
  }
  return;
}

/**
 * Perform database operations corresponding to permissions
 *
 * @param err Error object
 * @Param tokenId
 * @Param permission indicates permission to be verified
 */
function addPermissionUsedRecordInCallBack(err: BusinessError, tokenId: string, permission: Permissions) {
  // add Permission Used Record
  if (hasNoError(err)) {
    try {
      privacyManager.addPermissionUsedRecord(Number(tokenId), permission, SUCCESS_COUNT, 0)
        .then(() => {
          console.log('addPermissionUsedRecord success Permission is ' + permission);
        })
        .catch((err: BusinessError) => {
          console.log(`addPermissionUsedRecord fail, err->${JSON.stringify(err)}`);
        });
    } catch (err) {
      console.log(`catch err->${JSON.stringify(err)}`);
    }
  } else {
    try {
      privacyManager.addPermissionUsedRecord(Number(tokenId), permission, 0, FAIL_COUNT)
        .then(() => {
          console.log('addPermissionUsedRecord success Permission is ' + permission);
        })
        .catch((err: BusinessError) => {
          console.log(`addPermissionUsedRecord fail, err->${JSON.stringify(err)}`);
        });
    } catch (err) {
      console.log(`catch err->${JSON.stringify(err)}`);
    }
  }
  return;
}

/**
 * Perform database operations corresponding to high-level permissions
 *
 * @Param uri indicates user's input uri
 * @Param dataParameter indicates database operation information to be performed
 */
async function dataOperateSelectorByHighAuthority(uri: string, dataParameter: DataParameter) {
  let operationName = dataParameter.operationName;
  let columns = dataParameter.columns;
  let predicates = dataParameter.predicates;
  let value = dataParameter.value;
  let callback = dataParameter.callback;
  switch (operationName) {
    case INSERT_BY_PROXY_OPERATION_NAME:
      if (value instanceof Array) {
        delegate.batchInsertByHighAuthority(uri, value as ValuesBucket[], callback);
        break;
      }
      delegate.insertByHighAuthority(uri, value as ValuesBucket, callback);
      break;
    case UPDATE_BY_PROXY_OPERATION_NAME:
      delegate.updateByHighAuthority(uri, value as ValuesBucket, predicates, callback);
      break;
    case DELETE_BY_PROXY_OPERATION_NAME:
      delegate.deleteByHighAuthority(uri, predicates, callback);
      break;
    case QUERY_BY_PROXY_OPERATION_NAME:
      delegate.queryByHighAuthority(uri, columns, predicates, callback);
      break;
    default:
      break;
  }
}

/**
 * Perform database operations corresponding to low-level permissions
 *
 * @Param uri indicates user's input uri
 * @Param dataParameter indicates database operation information to be performed
 */
async function dataOperateSelectorByLowAuthority(uri: string, dataParameter: DataParameter) {
  let operationName = dataParameter.operationName;
  let columns = dataParameter.columns;
  let predicates = dataParameter.predicates;
  let value = dataParameter.value;
  let callback = dataParameter.callback;
  switch (operationName) {
    case INSERT_BY_PROXY_OPERATION_NAME:
      if (value instanceof Array) {
        delegate.batchInsertByLowAuthority(uri, value as ValuesBucket[], callback);
        break;
      }
      delegate.insertByLowAuthority(uri, value as ValuesBucket, callback);
      break;
    case UPDATE_BY_PROXY_OPERATION_NAME:
      delegate.updateByLowAuthority(uri, value as ValuesBucket, predicates, callback);
      break;
    case DELETE_BY_PROXY_OPERATION_NAME:
      delegate.deleteByLowAuthority(uri, predicates, callback);
      break;
    case QUERY_BY_PROXY_OPERATION_NAME:
      delegate.queryByLowAuthority(uri, columns, predicates, callback);
      break;
    default:
      break;
  }
}

/**
 * List of operation parameters for database operation
 *
 * @since 2022-12-28
 */
abstract class DataParameter {
  operationName: string = '';

  value: data_rdb.ValuesBucket | data_rdb.ValuesBucket[] = {};

  columns: Array<string> = [];

  predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();

  callback: Function = (err: BusinessError, count: number) => {
  };
}

/**
 * List of operation parameters for insert operation
 *
 * @since 2022-12-28
 */
class InsertDataParameter extends DataParameter {
  constructor(value: data_rdb.ValuesBucket | data_rdb.ValuesBucket[]) {
    super();
    this.value = value;
  }
}

/**
 * List of operation parameters for delete operation
 *
 * @since 2022-12-28
 */
class DeleteDataParameter extends DataParameter {
  constructor(predicates: dataSharePredicates.DataSharePredicates) {
    super();
    this.predicates = predicates;
  }
}

/**
 * List of operation parameters for update operation
 *
 * @since 2022-12-28
 */
class UpdateDataParameter extends DataParameter {
  constructor(value: data_rdb.ValuesBucket, predicates: dataSharePredicates.DataSharePredicates) {
    super();
    this.value = value;
    this.predicates = predicates;
  }
}

/**
 * List of operation parameters for query operation
 *
 * @since 2022-10-28
 */
class QueryDataParameter extends DataParameter {
  constructor(columns: Array<string>, predicates: dataSharePredicates.DataSharePredicates) {
    super();
    this.columns = columns;
    this.predicates = predicates;
  }
}

export default new DataShareAbilityAuthenticateProxy()