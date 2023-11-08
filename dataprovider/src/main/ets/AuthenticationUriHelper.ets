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

import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { Log } from '@ohos/common/src/main/ets/utils/Log';

const TAG = "CalendarUriHelper"

/**
 * Verify whether the current calling application has this permission by tokenID
 *
 * @param tokenId indicates the user's tokenID ,the tokenID can be a string or number
 * @return the uri string without BundleName and TokenID in case of changing this data.
 */
export async function verifyAccessByTokenId(tokenId: string, permissionName: Permissions): Promise<boolean> {
  let atManager = abilityAccessCtrl.createAtManager();
  let result: abilityAccessCtrl.GrantStatus = 2;
  try {
    result = await atManager.checkAccessToken(Number.parseInt(tokenId), permissionName);
  } catch (err) {
    Log.error(TAG, `err=${err?.message}`);
  }

  if (result === null || result === undefined) {
    return false;
  }

  if (result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
    // Allow the visitor to call the interface provided by the current application
    Log.debug(TAG, "This application has been authorized to access");
    return true;
  }
  // Prohibit the visitor to call the interface provided by the current application
  Log.debug(TAG, "This application is NOT authorized to access");
  return false;
}