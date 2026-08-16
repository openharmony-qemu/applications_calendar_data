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

import common from '@ohos.app.ability.common';
import bundleManager from '@ohos.bundle.bundleManager';
import { Log } from './Log';
import type { BusinessError } from '@ohos.base';
import { resourceManager } from '@kit.LocalizationKit';

const TAG = 'GlobalThis';

export class GlobalThis {
  private static ins: GlobalThis;
  appContext: common.UIAbilityContext | null = null;
  extensionContext: common.ExtensionContext | null = null;
  bundleInfo: bundleManager.BundleInfo | null = null;

  private constructor() {
  }

  public static getInstance(): GlobalThis {
    if (!GlobalThis.ins) {
      GlobalThis.ins = new GlobalThis();
    }
    return GlobalThis.ins;
  }

  public static getSingleInstance(): GlobalThis {
    return GlobalThis.getInstance();
  }

  public static getAppContext(): common.UIAbilityContext | null {
    return GlobalThis.getInstance().appContext;
  }

  public static setAppContext(UiAbilityContext: common.UIAbilityContext): void {
    GlobalThis.getInstance().appContext = UiAbilityContext;
  }

  public static getExtensionContext(): common.ExtensionContext | null {
    return GlobalThis.getInstance().extensionContext;
  }

  public static setExtensionContext(ExtensionContext: common.ExtensionContext): void {
    GlobalThis.getInstance().extensionContext = ExtensionContext;
  }

  public getBasicContext(): common.Context | null {
    if (this.appContext) {
      return this.appContext;
    }
    if (this.extensionContext) {
      return this.extensionContext;
    }
    return null;
  }

  /**
   * 获取资源串
   *
   * @param resource 资源
   * @return 资源文本
   */
  public getResourceStr(resource: resourceManager.Resource): string {
    const context = GlobalThis.getSingleInstance().appContext;
    if (context) {
      let res = '';
      try {
        res = context.resourceManager.getStringSync(resource);
      } catch (err) {
        Log.error(TAG, `getResourceStr failed, code is ${err?.code},message is ${err?.message}`);
      }
      return res;
    }
    return '';
  }

  public getResourceStrParms(resource: resourceManager.Resource, ...args: Array<string | number>): string {
    if (!resource) {
      Log.error(TAG, 'No Valid resource when getResourceStrParms');
      return '';
    }
    const context = GlobalThis.getSingleInstance().appContext;
    if (!context) {
      Log.error(TAG, 'getResourceStrParms context is null');
      return '';
    }
    let res = '';
    try {
      res = context.resourceManager.getStringSync(resource, ...args);
    } catch (err) {
      Log.error(TAG, `getResourceStrParms failed, code is ${err?.code},message is ${err?.message}`);
    }
    return res;
  }

  public getPluralStr(resource: resourceManager.Resource, num: number): string {
    if (!resource) {
      Log.error(TAG, 'No Valid resource when getPluralStr');
      return '';
    }
    const context = GlobalThis.getSingleInstance().appContext;
    if (!context) {
      Log.error(TAG, 'getPluralStr context is null');
      return '';
    }
    let res = '';
    try {
      res = context.resourceManager.getPluralStringValueSync(resource, num);
    } catch (err) {
      Log.error(TAG, `getPluralStr failed, code is ${err?.code},message is ${err?.message}`);
    }
    return res;
  }

  public async getBundleInfo(): Promise<bundleManager.BundleInfo | null> {
    const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA;
    return new Promise((resolve) => {
      if (!this.bundleInfo) {
        bundleManager.getBundleInfoForSelf(bundleFlags).then((bundleInfo) => {
          this.bundleInfo = bundleInfo;
          resolve(this.bundleInfo);
        }).catch((error: BusinessError) => {
          Log.error(TAG, `get bundleInfo failed,error is ${error?.message}`);
          resolve(null);
        });
      } else {
        resolve(this.bundleInfo);
      }
    });
  }
}