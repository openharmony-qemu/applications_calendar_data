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

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { isEmptyStr } from '@ohos/common/src/main/ets/utils/TextUtils';

import { EventColumns, SEARCH_COLUMNS } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';
import { parseNumber } from '@ohos/common/src/main/ets/utils/TextUtils';

import { InstancesQueryParams } from './InstanceQueryParams';
import { ValueType } from '@kit.ArkData';

const TAG = 'InstancesQuerySqlGenerator';

export class QuerySqlResult {
  public sql: string | undefined;
  public args: ValueType[];

  constructor(sql: string | undefined, args: ValueType[]) {
    this.sql = sql;
    this.args = args;
  }
}

/**
 * generate instances associated query SQL from columns and query params(begin&end、searchText)
 *
 * @param columns Columns to be queried
 * @param params Parameter object containing begin&end or searchText
 */
export function generateInstancesQuerySql(columns: string[],
                                          params: InstancesQueryParams, callerName: string): QuerySqlResult {
  if ((params === null) || (params === undefined)) {
    Log.error(TAG, `generateInstancesQuerySql get invalid params`);
    return new QuerySqlResult(undefined, []);
  }

  const sqlArgs: ValueType[] = [];

  // 1.generate main body
  let sql = getSelectMainBody(columns);

  // 2.process begin&end fragment
  const hasBeginEnd = params.isValidBeginEnd();
  if (hasBeginEnd) {
    sql += getBeginEndSqlFragment(sqlArgs, params.getBegin(), params.getEnd());
  }

  // 3.if by low authority, process creator fragment use callerName
  if (!isEmptyStr(callerName)) {
    if (hasBeginEnd) {
      sql += ` AND`;
    }
    sql += getCreatorSqlFragment(sqlArgs, callerName);
  }

  // 4.process searchText fragment
  const searchText = params.getSearchText();
  const hasSearch = !isEmptyStr(searchText);
  if (hasSearch) {
    if (hasBeginEnd || !isEmptyStr(callerName)) {
      sql += ` AND`;
    }
    sql += getSearchSqlFragment(sqlArgs, searchText);

  }

  // 5.process eventIdStr fragment
  const eventIdStr = params.getEventIds();
  if (!isEmptyStr(eventIdStr)) {
    if (hasBeginEnd) {
      sql += ` AND`;
    }
    sql += getEventIdsSqlFragment(sqlArgs, eventIdStr);

  }

  // 6.process calendarId fragment
  const calendarId = params.getCalendarId();
  if ((calendarId && calendarId > 0)) {
    if (hasBeginEnd) {
      sql += ` AND`;
    }
    sql += getCalendarIdSqlFragment(sqlArgs, calendarId);

  }

  // 7.process orderBy fragment
  const orderByFragment: string = getOrderByFragment(params) as string;
  if (!isEmptyStr(orderByFragment)) {
    sql += orderByFragment;
  }

  // 8.return the full sql and args
  return new QuerySqlResult(sql, sqlArgs);
}

function getSelectMainBody(columns: string[]): string {
  let sql = 'SELECT ';

  // set select columns
  if ((columns === null) || (columns === undefined) || (columns.length === 0)) {
    sql += '*';
  } else {
    for (let index = 0; index < columns.length; index++) {
      let element = columns[index];
      if (columns[index] === '_id') {
        element = 'Events._id';
      }
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
  sql += ` ON (${instances}.${InstancesColumns.EVENT_UUID}=${events}.${EventColumns.UUID}) WHERE`;
  return sql;
}

function getCreatorSqlFragment(sqlArgs: ValueType[], creator: string): string {
  sqlArgs.push(creator);
  const fragment = ` (${InstancesColumns.TABLE_NAME}.${InstancesColumns.CREATOR} = ?)`;
  return fragment;
}

function getBeginEndSqlFragment(sqlArgs: ValueType[], begin: number, end: number): string {
  const beginRangeFragment = ` (${InstancesColumns.BEGIN} BETWEEN ? AND ?)`;
  const endRangeFragment = `(${InstancesColumns.END} BETWEEN ? AND ?)`;
  const unionRangeFragment = `(${InstancesColumns.BEGIN} <= ? AND ${InstancesColumns.END} >= ?)`;
  sqlArgs.push(begin, end, begin, end, begin, end);
  return `(${beginRangeFragment} OR ${endRangeFragment} OR ${unionRangeFragment})`;
}

function getSearchSqlFragment(sqlArgs: ValueType[], searchText: string): string {
  let fragment = ` (`;
  for (let i = 0, len = SEARCH_COLUMNS.length; i < len; i++) {
    if (i != 0) {
      fragment += ` OR `;
    }
    sqlArgs.push(`%${searchText}%`);
    fragment += `(${SEARCH_COLUMNS[i]} like ?)`;
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

function getEventIdsSqlFragment(sqlArgs: ValueType[], eventIdsStr: string): string {
  let fragment = ` (`;
  const eventIds = eventIdsStr.split(',');
  const size = eventIds.length;
  for (let i = 0; i < size; i++) {
    const id = parseNumber(eventIds[i]);
    if (id !== 0) {
      sqlArgs.push(id);
      fragment += `${EventColumns.TABLE_NAME}.${EventColumns.ID}=?`;
      if (i !== size - 1) {
        fragment += ' OR ';
      }
    }
  }
  fragment += `)`;
  return fragment;
}

function getCalendarIdSqlFragment(sqlArgs: ValueType[], calendarId: number): string {
  sqlArgs.push(calendarId);
  return ` (${EventColumns.TABLE_NAME}.${EventColumns.CALENDAR_ID} = ?)`;
}
