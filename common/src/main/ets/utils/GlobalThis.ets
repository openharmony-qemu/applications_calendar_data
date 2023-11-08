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

export class GlobalThis {
  private static ins: GlobalThis;
  UiAbilityContext: common.UIAbilityContext | null = null;
  ExtensionContext: common.ExtensionContext | null = null;

  private constructor() {
  }

  public static getInstance(): GlobalThis {
    if (!GlobalThis.ins) {
      GlobalThis.ins = new GlobalThis();
    }
    return GlobalThis.ins;
  }

  public static getUiAbilityContext(): common.UIAbilityContext | null {
    return GlobalThis.getInstance().UiAbilityContext;
  }

  public static setUiAbilityContext(UiAbilityContext: common.UIAbilityContext): void {
    GlobalThis.getInstance().UiAbilityContext = UiAbilityContext;
  }

  public static getExtensionContext(): common.ExtensionContext | null {
    return GlobalThis.getInstance().ExtensionContext;
  }

  public static setExtensionContext(ExtensionContext: common.ExtensionContext): void {
    GlobalThis.getInstance().ExtensionContext = ExtensionContext;
  }
}