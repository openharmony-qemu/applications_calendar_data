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

import UIAbility from '@ohos.app.ability.UIAbility';
import { Log } from '@ohos/common/src/main/ets/utils/Log'
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { GlobalThis } from '@ohos/common/src/main/ets/utils/GlobalThis';

const TAG = 'MainAbility';

export default class MainAbility extends UIAbility {
  onCreate(want: Want) {
    Log.log(TAG, "MainAbility onCreate");
  }

  onDestroy() {
    Log.log(TAG, "MainAbility onDestroy");
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    Log.log(TAG, "MainAbility onWindowStageCreate");

    windowStage.loadContent("pages/index", (err: BusinessError, data) => {
      if (err.code) {
        Log.error(TAG, 'Failed to load content. Cause: ' + JSON.stringify(err) ?? '');
        return;
      }
      Log.info(TAG, 'Success in loading the content. Data: ' + JSON.stringify(data) ?? '');
    });
    GlobalThis.setUiAbilityContext(this.context);
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    Log.log(TAG, "MainAbility onWindowStageDestroy");
  }

  onForeground() {
    // Ability has brought to foreground
    Log.log(TAG, "MainAbility onForeground");
  }

  onBackground() {
    // Ability has back to background
    Log.log(TAG, "MainAbility onBackground");
  }
};
