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

interface mapAddressHistoryColumnsType {
  TABLE_NAME: string,
  ID: string,
  ADDRESS: string,
  NAME: string,
  LAT: string,
  LON: string,
  TIME: string,
  DATA1: string,
  DATA2: string,
}

/**
 * the const of table MapAddressHistory
 *
 * @since 2022-09-08
 */
export const MapAddressHistoryColumns: mapAddressHistoryColumnsType = {
  TABLE_NAME: 'map_address_history',
  ID: '_id',
  ADDRESS: 'address',
  NAME: 'name',
  LAT: 'lat',
  LON: 'lon',
  TIME: 'time',
  DATA1: 'data1',
  DATA2: 'data2',
}