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

import { isEmptyStr, isUninterrupted } from '@ohos/common/src/main/ets/utils/TextUtils';
import { getQueries } from '@ohos/common/src/main/ets/utils/UrlUtils';
import { Log } from "@ohos/common/src/main/ets/utils/Log";

const KEY_RANGE_BEGIN = 'begin';

const KEY_RANGE_END = 'end';

const KEY_SEARCH_TEXT = 'searchText';

const KEY_ORDER_BY_ASC = 'orderByAsc';

const KEY_ORDER_BY_DESC = 'orderByDesc';

const TAG = 'InstancesQueryParams';

// max length (16 chinese) of search text, The excess part will be discarded.
const MAX_SEARCH_LENGTH = 32;

/**
 * the class contains Instances query Params
 *
 * @since 2022-09-02
 */
export class InstancesQueryParams {
  begin?: number
  end?: number
  searchText?: string
  orderByAsc?: string
  orderByDesc?: string

  constructor() {
  }

  /**
   * judge is valid begin&end params:
   * 1.has valid begin&end value
   * 2.begin&end >0
   * 3.begin<end
   *
   * @param begin the begin params
   * @param end the end params
   */
  public isValidBeginEnd(): boolean {
    const begin = this.getBegin();
    const end = this.getEnd();
    if (begin === null || begin === undefined) {
      return false;
    }
    if (end === null || end === undefined) {
      return false;
    }
    return end >= 0 && end >= 0 && begin < end;
  }

  public getBegin(): number {
    return this.begin as number;
  }

  public setBegin(begin: number): void {
    this.begin = begin;
  }

  public getEnd(): number {
    return this.end as number;
  }

  public setEnd(end: number): void {
    this.end = end;
  }

  public getSearchText(): string {
    return this.searchText as string;
  }

  public setSearchText(searchText: string): void {
    this.searchText = searchText;
  }

  public getOrderByAsc(): string {
    return this.orderByAsc as string;
  }

  public setOrderByAsc(orderByAsc: string): void {
    this.orderByAsc = orderByAsc;
  }

  public getOrderByDesc(): string {
    return this.orderByDesc as string;
  }

  public setOrderByDesc(orderByDesc: string): void {
    this.orderByDesc = orderByDesc;
  }
}

/**
 * judge is valid params or not:
 * 1.invalid object -> false
 * 2.valid searchText -> true
 * 3.valid begin and end -> true
 * 4.or else -> false
 *
 * @param params object of InstancesQueryParams
 */
export function isValidQueryParams(params: InstancesQueryParams): boolean {
  if (params === null || params === undefined) {
    return false;
  }
  const isValidSearchText = !isEmptyStr(params.getSearchText());
  if (isValidSearchText) {
    return true;
  }
  return params.isValidBeginEnd();
}

/**
 * parse all params from uri
 *
 * @param uri uri from caller
 * @return result of InstancesQueryParams after parsed
 */
export function parseParamsFromUri(uri: string): InstancesQueryParams | undefined {
  const queryMap = getQueries(uri);
  if (queryMap === null || queryMap === undefined || queryMap.size <= 0) {
    Log.warn(TAG, 'parseBeginEndFromUri get invalid queryMap');
    return undefined;
  }
  const paramsResult = new InstancesQueryParams();

  parseBeginEndFromQueryMap(queryMap, paramsResult);

  parseSearchTextFromQueryMap(queryMap, paramsResult);

  parseOrderByFromQueryMap(queryMap, paramsResult);

  return paramsResult;
}

/**
 * try parse begin and end params from queryMap
 *
 * @param queryMap params map parsed from uri
 * @param params the object to save parse result
 */
function parseBeginEndFromQueryMap(queryMap: Map<string, string>, params: InstancesQueryParams): void {
  const beginStr = queryMap.get(KEY_RANGE_BEGIN) as string;
  const endStr = queryMap.get(KEY_RANGE_END) as string;
  if (isEmptyStr(beginStr) || isEmptyStr(endStr)) {
    Log.warn(TAG, 'parseBeginEndFromUri get invalid begin end str');
    return;
  }
  try {
    const beginTime = Number.parseInt(beginStr);
    const endTime = Number.parseInt(endStr);
    Log.debug(TAG, `parseBeginEndFromUri ${beginTime}/${endTime}`);
    params.setBegin(beginTime);
    params.setEnd(endTime);
  } catch (err) {
    Log.error(TAG, `parseBeginEndFromUri get err ${err}`);
  }
}

/**
 * try parse search params from queryMap
 *
 * @param queryMap params map parsed from uri
 * @param params the object to save parse result
 */
function parseSearchTextFromQueryMap(queryMap: Map<string, string>, params: InstancesQueryParams): void {
  let searchText = queryMap.get(KEY_SEARCH_TEXT) as string;
  if (isEmptyStr(searchText)) {
    return;
  }

  // decode for chinese search
  searchText = decodeURI(searchText);
  if (isEmptyStr(searchText)) {
    Log.warn(TAG, `the searchText is empty after decode`);
    return;
  }
  const originalText = searchText;

  // Crop the character string to the maximum length supported by the query.
  if (searchText.length > MAX_SEARCH_LENGTH) {
    searchText = searchText.substring(0, MAX_SEARCH_LENGTH);
  }

  // Replace characters to prevent SQL injection.
  searchText = getSecuritySearchText(searchText);

  params.setSearchText(searchText);

  if (originalText != searchText) {
    Log.info(TAG, `the searchText is converted from ${originalText} to ${searchText}`);
  }
}

/**
 * To prevent SQL injection, replace sql's separator characters to double characters.
 * And you need to add the ' symbol before and after searchText when splicing SQL statements.
 *
 * @param searchText search text before replace
 */
function getSecuritySearchText(searchText: string): string {
  /*
   * Separator characters of sql:
   * MySQL -> `
   * MS-SQL -> ]
   * PostgreSQL -> "
   * String separator -> '
   */
  return searchText.replace(RegExp("/(?<matchedText>[\`\]\"\'])/gm"), '$<matchedText>$<matchedText>');
}

/**
 * try parse orderBy params from queryMap
 *
 * @param queryMap params map parsed from uri
 * @param params the object to save parse result
 */
function parseOrderByFromQueryMap(queryMap: Map<string, string>, params: InstancesQueryParams): void {
  const orderByAsc = queryMap.get(KEY_ORDER_BY_ASC) as string;
  if (isUninterrupted(orderByAsc)) {
    params.setOrderByAsc(orderByAsc);
  }
  const orderByDesc = queryMap.get(KEY_ORDER_BY_DESC) as string;
  if (isUninterrupted(orderByDesc)) {
    params.setOrderByDesc(orderByDesc);
  }
}