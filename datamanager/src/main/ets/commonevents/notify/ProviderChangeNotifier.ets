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

import { CommonEventConstants } from '../CommonEventConstants';
import { sendBroadcast } from '@ohos/common/src/main/ets/broadcast/BroadcastHelper';
import { GlobalThis } from '@ohos/common/src/main/ets/utils/GlobalThis';
import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { CalendarsColumns, EventColumns, InstancesColumns } from '@ohos/datastructure';
import { common } from '@kit.AbilityKit';
import dataShare from '@ohos.data.dataShare';

const TAG = 'ProviderChangeNotifier';

export const OPERATION_INSERT: string = 'insert';

export const OPERATION_UPDATE: string = 'update';

export const OPERATION_DELETE: string = 'delete';

export const OPERATION_UNKNOWN: string = 'unknown';

const BROAD_CAST_DELAY: number = 100;

const PROXY_URI: string = 'datashareproxy://com.ohos.calendardata';

const PROXY_URI_CALENDAR: string = PROXY_URI + '/Calendars';

const DATA_SHARE_WHOLE_URI: string = 'datashare:///calendardata_whole';

const NOTIFY_PROXY_GAP: number = 2000;

const NOTIFY_PROXY_URI_DELAY: number = 200;

const NOTIFY_PROXY_URI_INTERVAL: number = 500;

let lastNotifyProxyTime: number = 0;

let notifyProxyTimerId: number = 0;

// 非静默的DataShareHelper，缓存避免多次创建
let dataShareHelper: dataShare.DataShareHelper | undefined = undefined;

interface ParametersI {
  table: string;
  operation: string;
}

interface DataI {
  parameters: ParametersI;
}

export function notifyProviderChange(tableName: string, operation: string) {
  const data: DataI = {
    parameters: {
      table: tableName,
      operation: operation,
    }
  };
  notifyCalendarCardRefresh(tableName);
  setTimeout(() => {
    sendBroadcast(CommonEventConstants.DATA_CHANGED, data);
  }, BROAD_CAST_DELAY);
}

function notifyCalendarCardRefresh(tableName: string) {
  const dsOptions: dataShare.DataShareHelperOptions = { isProxy: true };
  // 需要数据代理的表
  const proxyTables: string[] = [
    CalendarsColumns.TABLE_NAME,
    EventColumns.TABLE_NAME,
    InstancesColumns.TABLE_NAME
  ];

  if (!proxyTables.includes(tableName)) {
    return;
  }

  if (Math.abs(Date.now() - lastNotifyProxyTime) < NOTIFY_PROXY_GAP) {
    if (notifyProxyTimerId > 0) {
      clearTimeout(notifyProxyTimerId);
    }
    notifyProxyTimerId = setTimeout(() => {
      notifyCalendarCardRefresh(tableName);
    }, NOTIFY_PROXY_GAP);
    return;
  }
  lastNotifyProxyTime = Date.now();

  try {
    dataShare.createDataShareHelper(
      GlobalThis.getSingleInstance().getBasicContext(),
      PROXY_URI,
      dsOptions,
      async (err: BusinessError, helper: dataShare.DataShareHelper) => {
        helper.notifyChange(PROXY_URI_CALENDAR, () => {
          Log.warn(TAG, 'DataProxy notifyCalendarCardRefresh succeed');
        });
      });
  } catch (err) {
    Log.error(TAG, `notifyCalendarCardRefresh create dataShare err ${err?.message}`);
  }
}

export async function notifyCalendarAlertsChanged(tableName: string, changeType: dataShare.ChangeType,
                                                  values: Array<ValuesBucket>): Promise<void> {
  const dataShareContext: common.Context | null = GlobalThis.getExtensionContext();
  if (!dataShareContext) {
    Log.warn(TAG, `notifyProxyUriChanged context invalid`);
    return;
  }
  try {
    const begin: number = Date.now();
    if (!dataShareHelper) {
      dataShareHelper = await dataShare.createDataShareHelper(
        dataShareContext,
        DATA_SHARE_WHOLE_URI,
        { isProxy: false }
      );
    }
    if (!dataShareHelper) {
      Log.warn(TAG, `notifyProxyUriChanged helper invalid`);
      return;
    }
    const notifyUri: string = `${PROXY_URI}/${tableName}`;
    let data: dataShare.ChangeInfo = {
      type: changeType,
      uri: notifyUri,
      values: values
    }

    await dataShareHelper.notifyChange(data);
    Log.info(TAG, `DataProxy notifyChange ${tableName}, changeType:${changeType} succeed, cost ${Date.now() - begin}ms`);
  } catch (err) {
    Log.error(TAG, `notifyProxyUriChanged create dataShare err ${err?.code}, ${err?.message}`);
  }
}