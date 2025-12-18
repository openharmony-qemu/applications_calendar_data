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
DataShare::DataSharePredicates BuildCalendarFilter(const CalendarAccount &account);
const CalendarAccount defaultAccount{"phone", "local", ""};
const string calendarUrl = "datashare:///calendardata/Calendars";
const int MAX_ERR_NUM = 3;

CalendarManager::CalendarManager()
{
    uint64_t tokenId = CalendarEnv::GetInstance().GetTokenId();
    auto bumdleName = CalendarEnv::GetInstance().GetBundleName();
    auto bundleName_tokeId = "?bundleName=" + bumdleName + "&tokenId=" + std::to_string(tokenId);
    m_calendarUri = std::make_unique<Uri>(calendarUrl + bundleName_tokeId);
    //value_or_error = std::move(value);
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

std::variant<std::shared_ptr<Calendar>, Error> CalendarManager::CreateCalendar(const CalendarAccount &account)
{
    auto valueEvent = BuildValueCalendarAccount(account);
    int errNum = 0;
    std::variant<int, Error> result;
    Error error = {"", 0};
    do {
        result = DataShareHelperManager::GetInstance().Insert(*(m_calendarUri.get()), valueEvent);
        if (auto *errorRet = std::get_if<1>(&result)) {
            LOG_WARN("Insert error, code: %{public}d", errorRet->code);
            LOG_WARN("Insert indexNum %{public}d", errNum);
            error = *errorRet;
            errNum++;
        } else {
            error = {"", 0};
            break;
        }
    } while (errNum > 0 && errNum <= MAX_ERR_NUM);
    if (errNum > MAX_ERR_NUM) {
        return error;
    }
    return std::make_shared<Calendar>(account, std::get<int>(result));
}

DataShare::DataSharePredicates BuildCalendarFilter(const CalendarAccount &account)
{
    DumpCalendarAccount(account);
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("account_name", account.name);
    predicates.And();
    predicates.EqualTo("account_type", account.type);
    return predicates;
}

std::variant<std::shared_ptr<Calendar>, Error> CalendarManager::GetCalendar
    (const std::optional<CalendarAccount> &account)
{
    DataShare::DataSharePredicates predicates;
    Error error = {"", 0};
    if (account) {
        predicates = BuildCalendarFilter(account.value());
    } else {
        LOG_WARN("get defaultAccount");
        predicates = BuildCalendarFilter(defaultAccount);
    }
    std::vector<std::string> columns = {"_id", "account_name", "account_type", "calendar_displayName"};
    auto result = DataShareHelperManager::GetInstance()
        .Query(*(m_calendarUri.get()), predicates, columns);
    if (auto *errorRet = std::get_if<1>(&result)) {
        LOG_ERROR("query failed %{public}d, %{public}s", errorRet->code, errorRet->message.c_str());
        error = *errorRet;
        error.message = "GetCalendar error!";
        return error;
    }
    auto resultSet = std::get<0>(result);
    auto calendarSet = ResultSetToCalendars(resultSet);
    if (calendarSet.empty()) {
        LOG_WARN("calendarSet empty");
        error.code = QUERY_RESULT_EMPTY;
        error.message = "GetCalendar failed!";
        return error;
    }
    LOG_INFO("GetCalendar successed");
    return calendarSet.at(0);
}

std::variant<std::vector<std::shared_ptr<Calendar>>, Error> CalendarManager::GetAllCalendars()
{
    std::vector<std::shared_ptr<Calendar>> results;
    DataShare::DataSharePredicates predicates;
    std::vector<std::string> columns = {"_id", "account_name", "account_type", "calendar_displayName"};
    auto queryResult = DataShareHelperManager::GetInstance()
        .Query(*(m_calendarUri.get()), predicates, columns);
    if (auto *error = std::get_if<1>(&queryResult)) {
        LOG_ERROR("query failed %{public}d, %{public}s", error->code, error->message.c_str());
        return *error;
    } else {
        auto calendarRet = std::get<0>(queryResult);
        return ResultSetToCalendars(calendarRet);
    }
}

std::variant<bool, Error> CalendarManager::DeleteCalendar(const Calendar &calendar)
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", calendar.GetId());
    int errNum = 0;
    std::variant<int, Error> result = 0;
    Error error;
    do {
        result = DataShareHelperManager::GetInstance().Delete(*(m_calendarUri.get()), predicates);
        if (auto *errorRet = std::get_if<1>(&result)) {
            LOG_WARN("DeleteCalendar error, code: %{public}d", errorRet->code);
            LOG_WARN("Insert indexNum %{public}d", errNum);
            error = *errorRet;
            errNum++;
        } else {
            error = {"", 0};
            break;
        }
    } while (errNum > 0 && errNum <= MAX_ERR_NUM);
    if (errNum > MAX_ERR_NUM) {
        return error;
    }
    return std::get<0>(result) == 1;
}

int CalendarManager::DeleteAllCalendars()
{
    auto results = GetAllCalendars();
    int count = 0;
    if (auto *calendars = std::get_if<0>(&results)) {
        for (const auto &calendar : *calendars) {
            auto result = DeleteCalendar(*calendar.get());
            auto *delRet = std::get_if<0>(&result);
            if (*delRet) {
                count += 1;
            }
        }
    }
    return count;
}

}  // namespace OHOS::CalendarApi::Native
