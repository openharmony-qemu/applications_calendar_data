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
#ifndef CJ_CALENDAR_H
#define CJ_CALENDAR_H

#include <cstdint>
#include <vector>
#include "calendar_manager_ffi.h"
#include "cj_common_ffi.h"
#include "ffi_remote_data.h"
#include "cj_native_calendar.h"

namespace OHOS {
namespace CalendarApi {
std::vector<int64_t> ArrayI64ToVector(CArrI64 arr);
CArrI64 VectorToArrayI64(const std::vector<int64_t> &vec, int32_t* errcode);
char *IMallocCString(const std::string &origin);
class CJCalendar : public OHOS::FFI::FFIData {
    DECL_TYPE(CJCalendar, OHOS::FFI::FFIData)
public:
    explicit CJCalendar(std::shared_ptr<Native::CJNativeCalendar> calendar);
    ~CJCalendar() override = default;
    std::shared_ptr<Native::CJNativeCalendar>& GetNative();
    Event CEventToEvent(CEvent event);
    CEvent CEventInit();
    CArrEvents VectorToCArrEvents(std::vector<Event> events, int32_t* errcode);
    RecurrenceRule BuildNativeRecurrenceRule(CRecurrenceRule recurrenceRule);
    CRecurrenceRule BuildCRecurrenceRule(RecurrenceRule nativeRecurrenceRule, int32_t* errcode);
    CLocation BuildCLocation(Location location);
    CArrAttendee BuildCArrAttendee(vector<Attendee> attendees, int32_t* errcode);
    int64_t AddEvent(CEvent event, int32_t* errcode);
    void AddEvents(CArrEvents event, int32_t* errcode);
    void DeleteEvent(int64_t eventId, int32_t* errcode);
    void DeleteEvents(CArrI64 eventIds, int32_t* errcode);
    void UpdateEvent(CEvent event, int32_t* errcode);
    CArrEvents GetEvents(int64_t eventFilterId, CArrString eventKey, int32_t* errcode);
    CCalendarConfig GetConfig(int32_t* errcode);
    void SetConfig(CCalendarConfig config, int32_t* errcode);
    CCalendarAccount GetAccount(int32_t* errcode);
    std::shared_ptr<OHOS::CalendarApi::Native::CJNativeCalendar> calendar_ = nullptr;
};

}
}

#endif // CJ_CALENDAR_H