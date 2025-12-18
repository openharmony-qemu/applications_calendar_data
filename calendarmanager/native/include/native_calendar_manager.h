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

#ifndef NATIVE_CALENDAR_MANAGER_H
#define NATIVE_CALENDAR_MANAGER_H

#include <map>
#include "singleton.h"
#include "calendar_define.h"
#include "native_calendar.h"
#include "uri.h"
using Uri = OHOS::Uri;
namespace OHOS::CalendarApi::Native {
// template <typename T>
class CalendarManager {
public:
    // using ValueOrError = std::variant<T, Error>;
    static CalendarManager &GetInstance();
    CalendarManager();
    ~CalendarManager() {};
    static bool IsDefaultAccount(const CalendarAccount& account);
    std::variant<std::shared_ptr<Calendar>, Error> CreateCalendar(const CalendarAccount& account);
    std::variant<std::shared_ptr<Calendar>, Error> GetCalendar(const std::optional<CalendarAccount>& account);
    std::variant<std::vector<std::shared_ptr<Calendar>>, Error> GetAllCalendars();
    std::variant<bool, Error> DeleteCalendar(const Calendar& calendar);
    int DeleteAllCalendars();
private:
    std::unique_ptr<Uri> m_calendarUri;
    //ValueOrError value_or_error;
};
}

#endif