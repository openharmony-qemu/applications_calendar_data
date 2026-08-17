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

import AlertsUpdateJudge from './AlertsUpdateJudger';
import InsertAlertsUpdateJudger from './impl/InsertAlertsUpdateJudger';
import UpdateAlertsUpdateJudger from './impl/UpdateAlertsUpdateJudger';
import DeleteAlertsUpdateJudger from './impl/DeleteAlertsUpdateJudger';
import { AlertsOperationName } from '../../../constants/OperationConstant';

/**
 * AlarmNeedUpdateJudger 的工厂方法类，提供AlarmNeedUpdateJudger的创建与初始化，用来判断在不同场景中是否需要刷新alerts表
 *
 * @since 2024-12-09
 */
class AlertsUpdateJudgerFactory {
  private map: Map<string, AlertsUpdateJudge> = new Map();

  constructor() {
    this.map.set(AlertsOperationName.INSERT, new InsertAlertsUpdateJudger());
    this.map.set(AlertsOperationName.UPDATE, new UpdateAlertsUpdateJudger());
    this.map.set(AlertsOperationName.DELETE, new DeleteAlertsUpdateJudger());
  }

  public getAlertsUpdateJudger(judgerType: string): AlertsUpdateJudge | undefined {
    return this.map.has(judgerType) ? this.map.get(judgerType) : undefined;
  }
}

export default new AlertsUpdateJudgerFactory();