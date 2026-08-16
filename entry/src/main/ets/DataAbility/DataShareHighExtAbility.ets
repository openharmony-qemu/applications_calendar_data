/**
 * @file Describe the file
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import Extension from '@ohos.application.DataShareExtensionAbility';

import { Log } from '@ohos/common/src/main/ets/utils/Log';

import DoOperation from '@ohos/dataprovider/src/main/ets/DataShareAbilityDoOperation';

import { ValuesBucket } from '@ohos.data.ValuesBucket';

import { AsyncCallback } from '@ohos.base';

import dataSharePredicates from '@ohos.data.dataSharePredicates';

import { Permissions } from '@ohos.privacyManager';
import Want from '@ohos.app.ability.Want';
import { GlobalThis } from '@ohos/common';

const TAG: string = 'DataShareHighExtAbility';

const WRITE_WHOLE_CALENDAR: Permissions = 'ohos.permission.WRITE_WHOLE_CALENDAR';
const READ_WHOLE_CALENDAR: Permissions = 'ohos.permission.READ_WHOLE_CALENDAR';

export default class DataShareHighExtAbility extends Extension {
  onCreate(want: Want, callback: Function) {
    Log.info(TAG, '[onCreate] enter');
    try {
      GlobalThis.setExtensionContext(this.context);
      DoOperation.tryInitDatabase();
      callback();
    } catch (err) {
      Log.error(TAG, `err=${err?.message}`);
    }
    Log.info(TAG, '[onCreate] leave');
  }

  insert(uri: string, value: ValuesBucket, callback: AsyncCallback<number>) {
    DoOperation.doInsert(uri, value, WRITE_WHOLE_CALENDAR, callback);
  }

  batchInsert(uri: string, value: ValuesBucket[], callback: AsyncCallback<number>) {
    DoOperation.doBatchInsert(uri, value, WRITE_WHOLE_CALENDAR, callback);
  }

  update(uri: string, predicates: dataSharePredicates.DataSharePredicates, value: ValuesBucket,
         callback: AsyncCallback<number>) {
    DoOperation.doUpdate(uri, predicates, value, WRITE_WHOLE_CALENDAR, callback);
  }

  query(uri: string, predicates: dataSharePredicates.DataSharePredicates, columns: Array<string>,
        callback: AsyncCallback<Object>) {
    DoOperation.doQuery(uri, predicates, columns, READ_WHOLE_CALENDAR, callback);
  }

  delete(uri: string, predicates: dataSharePredicates.DataSharePredicates, callback: AsyncCallback<number>) {
    DoOperation.doDelete(uri, predicates, WRITE_WHOLE_CALENDAR, callback);
  }
}