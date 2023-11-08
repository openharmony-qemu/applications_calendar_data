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

import InsertOrUpdateAlertsUpdateJudgerImpl from './judger/InsertOrUpdateAlertsJudgerImpl';
import DeleteAlertsUpdateJudgerImpl from './judger/DeleteAlertsUpdateJudgerImpl';
import AlertsUpdateJudger from './AlertsUpdateJudger';

export const INSERT_OPERATION_NAME = 'insert';

export const UPDATE_OPERATION_NAME = 'update';

export const DELETE_OPERATION_NAME = 'delete';

/**
 * AlarmNeedUpdateJudger 的工厂方法类，提供AlarmNeedUpdateJudger的创建与初始化
 * AlarmNeedUpdateJudger 被设计用来判断在不同场景中是否需要刷新alerts表
 *
 * @since 2022-09-09
 */
export default class AlertsUpdateJudgerFactory {
  map: Map<string, AlertsUpdateJudger> = new Map();

  constructor() {
    this.map.set(INSERT_OPERATION_NAME, new InsertOrUpdateAlertsUpdateJudgerImpl());
    this.map.set(UPDATE_OPERATION_NAME, new InsertOrUpdateAlertsUpdateJudgerImpl());
    this.map.set(DELETE_OPERATION_NAME, new DeleteAlertsUpdateJudgerImpl());
  }

  getAlertsUpdateJudger(judgerType: string): AlertsUpdateJudger | undefined {
    return this.map.has(judgerType) ? this.map.get(judgerType) : undefined;
  }
}