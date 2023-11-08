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

interface ColorsColumnsType {
  TABLE_NAME: string;
  ID: string;
  ACCOUNT_NAME: string;
  ACCOUNT_TYPE: string;
  DATA: string;
  COLOR_TYPE: string;
  COLOR_INDEX: string;
  COLOR: string;
}

/**
 * the const of table Colors
 *
 * @since 2022-09-08
 */
export const ColorsColumns: ColorsColumnsType = {
  TABLE_NAME: 'Colors',
  ID: '_id',
  ACCOUNT_NAME: 'account_name',
  ACCOUNT_TYPE: 'account_type',
  DATA: 'data',
  COLOR_TYPE: 'color_type',
  COLOR_INDEX: 'color_index',
  COLOR: 'color',
}