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

import { Log } from "@ohos/common/src/main/ets/utils/Log"
import { isEmptyStr } from '@ohos/common/src/main/ets/utils/TextUtils';

import { EventColumns, SEARCH_COLUMNS } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';

import { InstancesQueryParams } from './InstanceQueryParams';

const TAG = 'InstancesQuerySqlGenerator';

/**
 * generate instances associated query SQL from columns and query params(begin&end、searchText)
 *
 * @param columns Columns to be queried
 * @param params Parameter object containing begin&end or searchText
 */
export function generateInstancesQuerySql(columns: Array<string>, params: InstancesQueryParams, callerName: string): string | undefined {
  if (params === null || params === undefined) {
    Log.error(TAG, `generateInstancesQuerySql get invalid params`);
    return undefined;
  }

  // 1.generate main body
  let sql = getSelectMainBody(columns);

  // 2.process begin&end fragment
  const hasBeginEnd = params.isValidBeginEnd();
  if (hasBeginEnd) {
    sql += getBeginEndSqlFragment(params.getBegin(), params.getEnd());
  }

  // 3.if by low authority, process creator fragment use callerName
  let hasCaller: boolean;
  if (hasCaller = !isEmptyStr(callerName)) {
    if (hasBeginEnd) {
      sql += ` AND`;
    }
    sql += getCreatorSqlFragment(callerName);
  }

  // 4.process searchText fragment
  const searchText = params.getSearchText();
  const hasSearch = !isEmptyStr(searchText);
  if (hasSearch) {
    if (hasBeginEnd || hasCaller) {
      sql += ` AND`;
    }
    sql += getSearchSqlFragment(searchText);
  }

  // 5.process orderBy fragment
  const orderByFragment: string = getOrderByFragment(params) as string;
  if (!isEmptyStr(orderByFragment)) {
    sql += orderByFragment;
  }

  // 6.return the full sql
  return sql;
}

function getSelectMainBody(columns: Array<string>): string {
  let sql = 'SELECT ';

  // set select columns
  if (columns === null || columns === undefined || columns.length === 0) {
    sql += '*';
  } else {
    for (let index = 0; index < columns.length; index++) {
      const element = columns[index];
      if (index !== 0) {
        sql += ',';
      }
      sql += element;
    }
  }

  // inner join tables
  const events = EventColumns.TABLE_NAME;
  const instances = InstancesColumns.TABLE_NAME;
  sql += ` FROM ${instances} INNER JOIN ${events}`;
  sql += ` ON (${instances}.${InstancesColumns.EVENT_ID}=${events}.${EventColumns.ID}) WHERE`;
  return sql;
}

function getCreatorSqlFragment(creator: string): string {
  const fragment = ` (${InstancesColumns.TABLE_NAME}.${InstancesColumns.CREATOR} = '${creator}')`;
  return fragment;
}

function getBeginEndSqlFragment(begin: number, end: number): string {
  const beginRangeFragment = ` (${InstancesColumns.BEGIN} BETWEEN ${begin} AND ${end})`;
  const endRangeFragment = `(${InstancesColumns.END} BETWEEN ${begin} AND ${end})`;
  const unionRangeFragment = `(${InstancesColumns.BEGIN} <= ${begin} AND ${InstancesColumns.END} >= ${end})`;
  let fragment = `(${beginRangeFragment} OR ${endRangeFragment} OR ${unionRangeFragment})`;
  return fragment;
}

function getSearchSqlFragment(searchText: string): string {
  let fragment = ` (`;
  for (let i = 0, len = SEARCH_COLUMNS.length; i < len; i++) {
    if (i != 0) {
      fragment += ` OR `;
    }

    // add ' character to avoid SQL injection
    fragment += `(${SEARCH_COLUMNS[i]} like '%${searchText}%')`;
  }
  fragment += `)`;
  return fragment;
}

function getOrderByFragment(params: InstancesQueryParams): string | undefined {
  const orderByAsc = params.getOrderByAsc();
  const orderByDesc = params.getOrderByDesc();
  if (isEmptyStr(orderByAsc) && isEmptyStr(orderByDesc)) {
    return undefined;
  }
  let fragment = ' ORDER BY ';
  const hasAsc = !isEmptyStr(orderByAsc);
  const hasDesc = !isEmptyStr(orderByDesc);
  if (hasAsc) {
    fragment += `${orderByAsc} ASC`;
  }
  if (hasAsc && hasDesc) {
    fragment += `,`;
  }
  if (hasDesc) {
    fragment += `${orderByDesc} DESC`;
  }
  return fragment;
}