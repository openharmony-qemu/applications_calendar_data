/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

#ifndef CJ_NATIVE_CALENDAR_MANAGER_H
#define CJ_NATIVE_CALENDAR_MANAGER_H

#include <map>
#include "singleton.h"
#include "calendar_define.h"
#include "cj_native_calendar.h"
#include "uri.h"
#include "datashare_result_set.h"

using Uri = OHOS::Uri;
namespace OHOS::CalendarApi::Native {
class CJNativeCalendarManager {
public:
    static CJNativeCalendarManager &GetInstance();
    CJNativeCalendarManager();
    ~CJNativeCalendarManager() {};
    static bool IsDefaultAccount(const CalendarAccount& account);
    std::shared_ptr<CJNativeCalendar> CreateCalendar(const CalendarAccount& account);
    std::shared_ptr<CJNativeCalendar> GetCalendar(const std::optional<CalendarAccount>& account = std::nullopt);
    std::vector<std::shared_ptr<CJNativeCalendar>> GetAllCalendars();
    bool DeleteCalendar(const CJNativeCalendar& calendar);
private:
    std::unique_ptr<Uri> m_calendarUri;
};
}

#endif