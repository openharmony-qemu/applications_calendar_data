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

Result<std::shared_ptr<Calendar>> CalendarManager::CreateCalendar(const CalendarAccount &account)
{
    auto valueEvent = BuildValueCalendarAccount(account);
    int errNum = 0;
    Result<int> result(0);
    Error error = {"", 0};
    do {
        result = DataShareHelperManager::GetInstance().Insert(*(m_calendarUri.get()), valueEvent);
        if (result.is_err()) {
            LOG_WARN("Insert error, code: %{public}d", result.error().code);
            LOG_WARN("Insert indexNum %{public}d", errNum);
            error = result.error();
            errNum++;
        } else {
            error = {"", 0};
            break;
        }
    } while (errNum > 0 && errNum <= MAX_ERR_NUM);
    if (errNum > MAX_ERR_NUM) {
        return Result<std::shared_ptr<Calendar>>(error);
    }
    auto calendar = std::make_shared<Calendar>(account, result.value());
    return Result<std::shared_ptr<Calendar>>(calendar);
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

Result<std::shared_ptr<Calendar>> CalendarManager::GetCalendar
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
    if (result.is_err()) {
        LOG_ERROR("query failed %{public}d, %{public}s", result.error().code, result.error().message.c_str());
        error.code = result.error().code;
        error.message = "GetCalendar error!";
        return Result<std::shared_ptr<Calendar>>(error);
    }
    auto resultSet = result.value();
    auto calendarSet = ResultSetToCalendars(resultSet);
    if (calendarSet.empty()) {
        LOG_WARN("calendarSet empty");
        error.code = QUERY_RESULT_EMPTY;
        error.message = "GetCalendar failed!";
        return Result<std::shared_ptr<Calendar>>(error);
    }
    LOG_INFO("GetCalendar successed");
    return Result<std::shared_ptr<Calendar>>(calendarSet.at(0));
}

Result<std::vector<std::shared_ptr<Calendar>>> CalendarManager::GetAllCalendars()
{
    std::vector<std::shared_ptr<Calendar>> results;
    DataShare::DataSharePredicates predicates;
    std::vector<std::string> columns = {"_id", "account_name", "account_type", "calendar_displayName"};
    auto queryResult = DataShareHelperManager::GetInstance()
        .Query(*(m_calendarUri.get()), predicates, columns);
    if (queryResult.is_err()) {
        LOG_ERROR("query failed %{public}d, %{public}s", queryResult.error().code, queryResult.error().message.c_str());
        return Result<std::vector<std::shared_ptr<Calendar>>>(queryResult.error());
    } else {
        auto calendarRet = queryResult.value();
        return Result<std::vector<std::shared_ptr<Calendar>>>(ResultSetToCalendars(calendarRet));
    }
}

Result<bool> CalendarManager::DeleteCalendar(const Calendar &calendar)
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", calendar.GetId());
    int errNum = 0;
    Result<int> result(0);
    Error error;
    do {
        result = DataShareHelperManager::GetInstance().Delete(*(m_calendarUri.get()), predicates);
        if (result.is_err()) {
            LOG_WARN("DeleteCalendar error, code: %{public}d", result.error().code);
            LOG_WARN("Insert indexNum %{public}d", errNum);
            error.code = result.error().code;
            errNum++;
        } else {
            error = {"", 0};
            break;
        }
    } while (errNum > 0 && errNum <= MAX_ERR_NUM);
    if (errNum > MAX_ERR_NUM) {
        return Result<bool>(error);
    }
    return Result<bool>(result.value() == 1);
}

int CalendarManager::DeleteAllCalendars()
{
    auto results = GetAllCalendars();
    int count = 0;
    if (results.is_ok()) {
        auto calendars = results.value();
        for (const auto &calendar : calendars) {
            auto delRet = DeleteCalendar(*calendar.get());
            if (delRet.is_ok()) {
                count += 1;
            }
        }
    }
    return count;
}

}  // namespace OHOS::CalendarApi::Native
