/*
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

#include "data_share_helper_manager.h"
#include "calendar_log.h"

using namespace OHOS::DataShare;
namespace OHOS::CalendarApi {

void DataShareHelperManager::SetDataShareHelper(std::shared_ptr<DataShare::DataShareHelper> helper)
{
    dataShareHelper = helper;
}

std::shared_ptr<DataShare::DataShareHelper> DataShareHelperManager::GetDataShareHelper()
{
    return dataShareHelper;
}

int DataShareHelperManager::Insert(const Uri &uri, const DataShareValuesBucket &value)
{
    if (!dataShareHelper) {
        LOG_ERROR("dataShareHelper null");
        return -1;
    }
    return dataShareHelper->Insert(const_cast<Uri &>(uri), value);
}

int DataShareHelperManager::BatchInsert(const Uri &uri, const std::vector<DataShare::DataShareValuesBucket> &values)
{
    if (!dataShareHelper) {
        LOG_ERROR("dataShareHelper null");
        return -1;
    }
    return dataShareHelper->BatchInsert(const_cast<Uri &>(uri), values);
}

int DataShareHelperManager::Update(const Uri &uri, const DataSharePredicates &predicates,
    const DataShareValuesBucket &value)
{
    if (!dataShareHelper) {
        LOG_ERROR("dataShareHelper null");
        return -1;
    }
    return dataShareHelper->Update(const_cast<Uri &>(uri), predicates, value);
}

int DataShareHelperManager::Delete(const Uri &uri, const DataSharePredicates &predicates)
{
    if (!dataShareHelper) {
        LOG_ERROR("dataShareHelper null");
        return -1;
    }
    return dataShareHelper->Delete(const_cast<Uri &>(uri), predicates);
}

std::shared_ptr<DataShareResultSet> DataShareHelperManager::Query(const Uri &uri, const DataSharePredicates &predicates,
    std::vector<std::string> &columns, DatashareBusinessError *businessError)
{
    if (!dataShareHelper) {
        LOG_ERROR("dataShareHelper null");
        return nullptr;
    }
    return dataShareHelper->Query(const_cast<Uri &>(uri), predicates, columns, businessError);
}
}