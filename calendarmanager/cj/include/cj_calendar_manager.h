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

namespace OHOS {
namespace CalendarApi {

class CJCalendarManager : public OHOS::FFI::FFIData {
    DECL_TYPE(CJCalendarManager, OHOS::FFI::FFIData)
public:
    void GetCalendarManager(int64_t contextId, int32_t* errcode);
    int64_t CreateCalendar(CCalendarAccount calendarAccount, int32_t* errcode);
    void DeleteCalendar(int64_t calendarId, int32_t* errcode);
    int64_t GetCalendar(CCalendarAccount calendarAccount, int32_t* errcode);
    CArr64 GetAllCalendars(int32_t* errcode);
    int64_t EditerEvent(int64_t contextId, char* eventstr, int32_t* errcode);
private:
    bool hasInited = false;
};

}
}

#endif // CJ_CALENDAR_MANAGER_H