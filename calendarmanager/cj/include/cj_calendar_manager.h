/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef CJ_CALENDAR_MANAGER_H
#define CJ_CALENDAR_MANAGER_H

#include <cstdint>
#include <vector>
#include "cj_common_ffi.h"
#include "ffi_remote_data.h"
#include "calendar_manager_ffi.h"
#include "native_calendar.h"

namespace OHOS {
namespace CalendarApi {

class CJCalendarManager : public OHOS::FFI::FFIData {
    DECL_TYPE(CJCalendarManager, OHOS::FFI::FFIData)
public:
    static void GetCalendarManager(int64_t contextId, int32_t* errcode);
    static int64_t CreateCalendar(CCalendarAccount calendarAccount, int64_t* calendarId, int32_t* errcode);
    static void DeleteCalendar(int64_t calendarId, int32_t* errcode);
    static int64_t GetCalendar(CCalendarAccount calendarAccount, int64_t* calendarId, int32_t* errcode);
    static CArrI64 GetAllCalendars(int32_t* errcode);
    static int64_t EditerEvent(char* eventstr, int32_t* errcode);
};

}
}

#endif // CJ_CALENDAR_MANAGER_H