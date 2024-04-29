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

/**
 * AlertsUpdateJudger 类的接口，具体实现类以 场景名 + AlertsUpdateJudger +impl命名
 *
 * @since 2022-09-09
 */
export default interface AlertsUpdateJudger {
  /**
   * 判断不同表被修改的场景下，Alerts 是否需要被更新
   *
   * @Param tableName 被修改的表的表名
   * @Param values 修改操作的更新值
   * @Return 是否需要更新 Alerts 表
   */
  isNeedToUpdateAlerts(tableName: string, values: data_rdb.ValuesBucket | data_rdb.ValuesBucket[]): boolean;
}