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

import { isEmptyStr } from './TextUtils'

export const QUERY_START = '?';

export const QUERY_SPLIT = '&';

export const QUERY_CONNECTOR = '=';

export const BUNDLE_NAME = 'bundleName';

export const TOKEN_ID = 'tokenId';

/**
 * parse query params from Uri, like:
 * xxx?params1=value1&params2=value2&params3=value3
 *
 * @param url the url to be parsed.
 * @return map Describes the key-value pair of the query parameter.
 */
export function getQueries(url: string): Map<string, string> | undefined {
  if (url === null || url === undefined) {
    return undefined;
  }
  let startIndex = url.indexOf(QUERY_START) + 1;
  const totalLength = url.length;
  if (startIndex < 1 || startIndex >= totalLength) {
    return undefined;
  }
  const query = url.substring(startIndex);
  if (query === null || query === undefined || query.length < 1) {
    return undefined;
  }
  const array = query.split(QUERY_SPLIT);
  if (array === null || array === undefined || array.length < 1) {
    return undefined;
  }
  const map = new Map<string, string>();
  for (let i = 0; i < array.length; i++) {
    const item = array[i];
    if (isEmptyStr(item)) {
      continue;
    }

    const connectorIndex = item.indexOf(QUERY_CONNECTOR);
    if (connectorIndex <= 0 || connectorIndex + 1 >= item.length) {
      // QUERY_CONNECTOR at the first or last index is invalid
      continue;
    }
    const key = item.substring(0, connectorIndex);
    const value = item.substring(connectorIndex + 1);
    map.set(key, value);
  }
  return map;
}

/**
 * transfer the user input uri to TokenID
 *
 * @param uri the user input uri
 * @return the tokenID coming from user's input.if TokenID is undefined, this function will return ""
 */
export function getTokenIDByUri(uri: string): string {
  let queries = getQueries(uri);
  if (queries && queries.has(TOKEN_ID)) {
    return queries.get(TOKEN_ID) as string;
  }
  return "";
}

/**
 * transfer the user input uri to TokenID
 *
 * @param uri the user input uri
 * @return the bundleName coming from user's input.if TokenID is undefined, this function will return ""
 */
export function getBundleNameByUri(uri: string): string {
  let queries = getQueries(uri);
  if (queries && queries.has(BUNDLE_NAME)) {
    return queries.get(BUNDLE_NAME) as string;
  }
  return "";
}

/**
 * transfer the user input uri to BundleNameAndTokenIdFromUri
 *
 * @param uri the user input uri
 * @return the object containing bundleName and tokenID come from user's input.
 * if bundleName or TokenID is undefined, this function will return null object.
 */
export function getBundleNameAndTokenIDByUri(uri: string): BundleNameAndTokenIdFromUri {
  let queries = getQueries(uri);
  let bundleNameAndTokenIdFromUri: BundleNameAndTokenIdFromUri = new BundleNameAndTokenIdFromUri();
  if (queries && queries.has(TOKEN_ID) && queries.has(BUNDLE_NAME)) {
    bundleNameAndTokenIdFromUri = {
      bundleName: queries.get(BUNDLE_NAME) as string,
      tokenId: queries.get(TOKEN_ID) as string
    };
    return bundleNameAndTokenIdFromUri;
  }
  return bundleNameAndTokenIdFromUri;
}

/**
 * the structure of BundleName and tokenId which are got from user's uri.
 *
 * @since 2022-10-29
 */
export class BundleNameAndTokenIdFromUri {
  bundleName: string = '';
  tokenId: string = '';
}
