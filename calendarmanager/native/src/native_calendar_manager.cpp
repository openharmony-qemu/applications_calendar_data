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

#include "native_calendar_manager.h"
#include "data_share_helper_manager.h"
#include "calendar_env.h"
#include "calendar_log.h"
#include "native_util.h"

namespace OHOS::CalendarApi::Native {
DataShare::DataSharePredicates BuildCalendarFilter(const CalendarAccount& account);
const CalendarAccount defaultAccount {"phone", "local", ""};
const string calendarUrl = "datashare:///calendardata/Calendars";

CalendarManager::CalendarManager()
{
    uint64_t tokenId = CalendarEnv::GetInstance().GetTokenId();
    auto bumdleName = CalendarEnv::GetInstance().GetBundleName();
    auto bundleName_tokeId = "?bundleName=" + bumdleName + "&tokenId=" + std::to_string(tokenId);
    LOG_INFO("bundleName_tokeId: %{public}s", bundleName_tokeId.c_str());
    m_calendarUri = std::make_unique<Uri>(calendarUrl + bundleName_tokeId);
}

CalendarManager &CalendarManager::GetInstance()
{
    static CalendarManager instance;
    return instance;
}

bool CalendarManager::IsDefaultAccount(const CalendarAccount &account)
{
    return account.name == defaultAccount.name && account.type == defaultAccount.type;
}

auto BuildValueCalendarAccount(const CalendarAccount &account)
{
    DataShare::DataShareValuesBucket valuesBucket;
    valuesBucket.Put("account_name", account.name);
    valuesBucket.Put("account_type", account.type);
    if (account.displayName) {
        valuesBucket.Put("calendar_displayName", account.displayName.value());
    }

    return valuesBucket;
}

std::shared_ptr<Calendar> CalendarManager::CreateCalendar(const CalendarAccount& account)
{
    DataShare::DataSharePredicates predicates = BuildCalendarFilter(account);
    std::vector<std::string> columns = {"_id", "account_name", "account_type", "calendar_displayName"};
    DataShare::DatashareBusinessError error;
    auto resultSet = DataShareHelperManager::GetInstance().Query(*(m_calendarUri.get()), predicates, columns, &error);
    if (resultSet) {
        auto calendarSet = ResultSetToCalendars(resultSet);
        if (!calendarSet.empty()) {
            LOG_INFO("already exist");
            return std::make_shared<Calendar>(calendarSet.at(0)->GetAccount(), calendarSet.at(0)->GetId());
        }
    }
    auto valueEvent = BuildValueCalendarAccount(account);
    auto index = DataShareHelperManager::GetInstance().Insert(*(m_calendarUri.get()), valueEvent);
    LOG_DEBUG("Insert index %{public}d", index);
    if (index <= 0) {
        LOG_ERROR("Insert failed");
        return nullptr;
    }
    return std::make_shared<Calendar>(account, index);
}


DataShare::DataSharePredicates BuildCalendarFilter(const CalendarAccount& account)
{
    DumpCalendarAccount(account);
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("account_name", account.name);
    predicates.And();
    predicates.EqualTo("account_type", account.type);
    return predicates;
}

std::shared_ptr<Calendar> CalendarManager::GetCalendar(const std::optional<CalendarAccount>& account)
{
    DataShare::DataSharePredicates predicates;
    if (account) {
        predicates = BuildCalendarFilter(account.value());
    } else {
        LOG_WARN("get defaultAccount");
        predicates = BuildCalendarFilter(defaultAccount);
    }
    std::vector<std::string> columns = {"_id", "account_name", "account_type", "calendar_displayName"};
    DataShare::DatashareBusinessError error;
    auto resultSet = DataShareHelperManager::GetInstance().Query(*(m_calendarUri.get()), predicates, columns, &error);
    if (!resultSet) {
        LOG_ERROR("query failed %{public}d, %{public}s", error.GetCode(), error.GetMessage().c_str());
        return nullptr;
    }
    auto calendarSet = ResultSetToCalendars(resultSet);
    if (calendarSet.empty()) {
        LOG_WARN("calendarSet empty");
        return nullptr;
    }
    LOG_INFO("GetCalendar successed");
    return std::move(calendarSet.at(0));
}

std::vector<std::shared_ptr<Calendar>> CalendarManager::GetAllCalendars()
{
    std::vector<std::shared_ptr<Calendar>> results;
    DataShare::DataSharePredicates predicates;
    std::vector<std::string> columns = {"_id", "account_name", "account_type", "calendar_displayName"};
    DataShare::DatashareBusinessError error;
    auto queryResult = DataShareHelperManager::GetInstance().Query(*(m_calendarUri.get()), predicates, columns, &error);
    if (!queryResult) {
        LOG_ERROR("query failed %{public}d, %{public}s", error.GetCode(), error.GetMessage().c_str());
        return results;
    }
    return ResultSetToCalendars(queryResult);
}


bool CalendarManager::DeleteCalendar(const Calendar& calendar)
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", calendar.GetId());
    auto result = DataShareHelperManager::GetInstance().Delete(*(m_calendarUri.get()), predicates);
    LOG_INFO("DeleteCalendar %{public}d", result);
    return result == 1;
}

int CalendarManager::DeleteAllCalendars()
{
    auto calendars = GetAllCalendars();
    int count = 0;
    for (const auto &calendar: calendars) {
        if (DeleteCalendar(*calendar.get())) {
            count +=1;
        }
    }
    return count;
}

}
