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
#include "calendar_env.h"
#include "napi_env.h"
#include "accesstoken_kit.h"
#include "ipc_skeleton.h"
#include <thread>
#include <chrono>

namespace {
const std::string CALENDAR_DATA_URI = "datashare:///calendardata";
const std::string CALENDAR_DATA_WHOLE_URI = "datashare:///calendardata_whole";
const std::string PERMISSION_READ_NAME = "ohos.permission.READ_WHOLE_CALENDAR";
const std::string PERMISSION_WRITE_NAME = "ohos.permission.WRITE_WHOLE_CALENDAR";
const int DESTROY_DATASHARE_DELAY = 2 * 60 * 1000;
const int CHECK_INTERVAL_DIVIDER = 4;
const uint32_t MAX_RETRY_ATTEMPTS = 3;
}  // namespace

using namespace OHOS::DataShare;
using namespace std::chrono;

namespace OHOS::CalendarApi {
void DataShareHelperManager::SetDataShareHelper
(std::shared_ptr<DataShare::DataShareHelper> lowHelper, std::shared_ptr<DataShare::DataShareHelper> highHelper)
{
    m_lowHelper = lowHelper;
    m_highHelper = highHelper;
}

std::shared_ptr<DataShareHelper> DataShareHelperManager::JudgeDataShareHelper(bool isRead)
{
    int32_t ret = -1;
    if (isRead) {
        ret = Security::AccessToken::AccessTokenKit::
        VerifyAccessToken(IPCSkeleton::GetCallingTokenID(), PERMISSION_READ_NAME);
        LOG_INFO("CreateDataShareHelper read verify access result=%{public}d", ret);
    } else {
        ret = Security::AccessToken::AccessTokenKit::
        VerifyAccessToken(IPCSkeleton::GetCallingTokenID(), PERMISSION_WRITE_NAME);
        LOG_INFO("CreateDataShareHelper write verify access result=%{public}d", ret);
    }

    if (ret == Security::AccessToken::PERMISSION_GRANTED) {
        LOG_INFO("DataShareHelper in high permission");
        return m_highHelper;
    } else {
        LOG_INFO("DataShareHelper in low permission");
        return m_lowHelper;
    }
}

std::shared_ptr<DataShareHelper> DataShareHelperManager::CreateDataShareHelper(bool isRead)
{
    std::lock_guard<std::recursive_mutex> lock(dataShareLock);
    DataShareHelperManager::SetDataShareHelperTimer(DESTROY_DATASHARE_DELAY);
    uint32_t retryCount = 0;
    std::shared_ptr<DataShare::DataShareHelper> dataShareHelper = nullptr;
    do {
        if (m_highHelper && m_lowHelper) {
            break;
        }

        if (!CalendarEnvNapi::GetInstance().getContext()) {
            LOG_INFO("CalendarEnvNapi::GetInstance().getContext() is null");
            break;
        }

        m_highHelper =  DataShareHelper::Creator(
            CalendarEnvNapi::GetInstance().getContext()->GetToken(), CALENDAR_DATA_WHOLE_URI);
        m_lowHelper = DataShareHelper::Creator(
            CalendarEnvNapi::GetInstance().getContext()->GetToken(), CALENDAR_DATA_URI);
        if (m_highHelper && m_lowHelper) {
            break;
        }

        LOG_WARN("CreateDataShareHelper failed %{public}d times retired", retryCount);
        retryCount = retryCount + 1;
    } while (retryCount < MAX_RETRY_ATTEMPTS);

    dataShareHelper = JudgeDataShareHelper(isRead);
    if (!(dataShareHelper)) {
        LOG_ERROR("create dataShareHelper failed");
        return nullptr;
    }
    return dataShareHelper;
}

bool DataShareHelperManager::DestroyDataShareHelper()
{
    std::lock_guard<std::recursive_mutex> lock(dataShareLock);
    int64_t now = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
    if (useCount.load() > 0) {
        LOG_INFO("DestroyDataShareHelper dataShareHelper in use count: %{public}d", useCount.load());
        return false;
    }
    if (now >= expire) {
        if (m_highHelper) {
            LOG_INFO("DestroyDataShareHelper highHelper releasing");
            m_highHelper->Release();
            m_highHelper = nullptr;
        } else {
            LOG_INFO("DestroyDataShareHelper highHelper is null");
        }

        if (m_lowHelper) {
            LOG_INFO("DestroyDataShareHelper lowHelper releasing");
            m_lowHelper->Release();
            m_lowHelper = nullptr;
        } else {
            LOG_INFO("DestroyDataShareHelper lowHelper is null");
        }

        return true;
    }
    LOG_INFO("DestroyDataShareHelper dataShareHelper not expired %{public}lld remaining", expire - now);
    return false;
}

void DataShareHelperManager::SetDataShareHelperTimer(int milliseconds)
{
    int64_t curtime = duration_cast<std::chrono::milliseconds>(system_clock::now().time_since_epoch()).count();
    expire.store(curtime + milliseconds, std::memory_order_seq_cst);
    if (m_lowHelper && m_highHelper) {
        return;
    }
    LOG_INFO("SetDataShareHelperTimer expireTime=%{public}lld", expire.load());
    std::thread th([&]() {
        do {
            std::this_thread::sleep_for(std::chrono::milliseconds(DESTROY_DATASHARE_DELAY / CHECK_INTERVAL_DIVIDER));
        } while (!DestroyDataShareHelper());
    });
    th.detach();
}

std::shared_ptr<DataShare::DataShareHelper> DataShareHelperManager::GetDataShareHelper(bool isRead)
{
    return CreateDataShareHelper(isRead);
}

int DataShareHelperManager::Insert(const Uri &uri, const DataShareValuesBucket &value)
{
    auto dataShareHelper = CreateDataShareHelper(false);
    if (!dataShareHelper) {
        LOG_ERROR("Insert dataShareHelper is nullptr");
        return -1;
    }
    useCount.fetch_add(1, std::memory_order_seq_cst);
    auto res = dataShareHelper->Insert(const_cast<Uri &>(uri), value);
    useCount.fetch_sub(1, std::memory_order_seq_cst);
    return res;
}

int DataShareHelperManager::BatchInsert(const Uri &uri, const std::vector<DataShare::DataShareValuesBucket> &values)
{
    auto dataShareHelper = CreateDataShareHelper(false);
    if (!dataShareHelper) {
        LOG_ERROR("BatchInsert dataShareHelper is nullptr");
        return -1;
    }
    useCount.fetch_add(1, std::memory_order_seq_cst);
    auto res = dataShareHelper->BatchInsert(const_cast<Uri &>(uri), values);
    useCount.fetch_sub(1, std::memory_order_seq_cst);
    return res;
}

int DataShareHelperManager::Update(
    const Uri &uri, const DataSharePredicates &predicates, const DataShareValuesBucket &value)
{
    auto dataShareHelper = CreateDataShareHelper(false);
    if (!dataShareHelper) {
        LOG_ERROR("Update dataShareHelper is nullptr");
        return -1;
    }
    useCount.fetch_add(1, std::memory_order_seq_cst);
    auto res = dataShareHelper->Update(const_cast<Uri &>(uri), predicates, value);
    useCount.fetch_sub(1, std::memory_order_seq_cst);
    return res;
}

int DataShareHelperManager::Delete(const Uri &uri, const DataSharePredicates &predicates)
{
    auto dataShareHelper = CreateDataShareHelper(false);
    if (!dataShareHelper) {
        LOG_ERROR("Delete dataShareHelper is nullptr");
        return -1;
    }
    useCount.fetch_add(1, std::memory_order_seq_cst);
    auto res = dataShareHelper->Delete(const_cast<Uri &>(uri), predicates);

    useCount.fetch_sub(1, std::memory_order_seq_cst);
    return res;
}

std::shared_ptr<DataShareResultSet> DataShareHelperManager::Query(const Uri &uri, const DataSharePredicates &predicates,
    std::vector<std::string> &columns, DatashareBusinessError *businessError)
{
    auto dataShareHelper = CreateDataShareHelper(true);
    if (!dataShareHelper) {
        LOG_ERROR("Query dataShareHelper is nullptr");
        return nullptr;
    }
    useCount.fetch_add(1, std::memory_order_seq_cst);
    auto res = dataShareHelper->Query(const_cast<Uri &>(uri), predicates, columns, businessError);
    useCount.fetch_sub(1, std::memory_order_seq_cst);
    return res;
}
}  // namespace OHOS::CalendarApi