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
#include "ability_runtime/cj_ability_context.h"
#include "calendar_manager_ffi.h"
#include "cj_calendar_manager.h"
#include "cj_calendar.h"
#include "cj_event_filter.h"
#include "native/ffi_remote_data.h"
#include "ipc_skeleton.h"
#include "calendar_define.h"
#include "calendar_log.h"
#include "calendar_env.h"

using namespace OHOS;
using namespace OHOS::AbilityRuntime;
using namespace OHOS::CalendarApi;
using namespace OHOS::FFI;
using namespace OHOS::DataShare;

namespace OHOS {
namespace CalendarApi {
    std::vector<int64_t> ArrayI64ToVector(CArrI64 arr)
    {
        std::vector<int64_t> vec;
        for (int64_t i = 0; i < arr.size; i++) {
            vec.push_back(arr.head[i]);
        }
        return vec;
    }

    CArrI64 VectorToArrayI64(const std::vector<int64_t> &vec)
    {
        CArrI64 arr;
        arr.size = vec.size();
        arr.head = (int64_t *)malloc(sizeof(int64_t) * vec.size());
        for (int64_t i = 0; i < vec.size(); i++) {
            arr.head[i] = vec[i];
        }
        return arr;
    }

    char* IMallocCString(const std::string &origin)
    {
        if (origin.empty()) {
            return nullptr;
        }
        auto length = origin.length() + 1;
        char *res = static_cast<char *>(malloc(sizeof(char) * length));
        if (res == nullptr) {
            return nullptr;
        }
        return std::char_traits<char>::copy(res, origin.c_str(), length);
    }

    RecurrenceRule CJCalendar::BuildNativeRecurrenceRule(CRecurrenceRule recurrenceRule)
    {
        RecurrenceRule nativeRecurrenceRule;
        nativeRecurrenceRule.recurrenceFrequency = RecurrenceType(recurrenceRule.recurrenceFrequency);
        nativeRecurrenceRule.expire = std::make_optional<int64_t>(recurrenceRule.expire);
        nativeRecurrenceRule.count = std::make_optional<int64_t>(recurrenceRule.count);
        nativeRecurrenceRule.interval = std::make_optional<int64_t>(recurrenceRule.interval);
        nativeRecurrenceRule.excludedDates =
            std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(recurrenceRule.excludedDates));
        nativeRecurrenceRule.daysOfWeek =
            std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(recurrenceRule.daysOfWeek));
        nativeRecurrenceRule.daysOfMonth =
            std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(recurrenceRule.daysOfMonth));
        nativeRecurrenceRule.daysOfYear =
            std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(recurrenceRule.daysOfYear));
        nativeRecurrenceRule.weeksOfMonth =
            std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(recurrenceRule.weeksOfMonth));
        nativeRecurrenceRule.weeksOfYear =
            std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(recurrenceRule.weeksOfYear));
        nativeRecurrenceRule.monthsOfYear =
            std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(recurrenceRule.monthsOfYear));
        return nativeRecurrenceRule;
    }

    CRecurrenceRule CJCalendar::BuildCRecurrenceRule(RecurrenceRule nativeRecurrenceRule)
    {
        CRecurrenceRule cRecurrenceRule;
        cRecurrenceRule.recurrenceFrequency = nativeRecurrenceRule.recurrenceFrequency;
        if (nativeRecurrenceRule.expire.has_value()) {
            cRecurrenceRule.expire = nativeRecurrenceRule.expire.value();
        }
        if (nativeRecurrenceRule.count.has_value()) {
            cRecurrenceRule.count = nativeRecurrenceRule.count.value();
        }
        if (nativeRecurrenceRule.interval.has_value()) {
            cRecurrenceRule.interval = nativeRecurrenceRule.interval.value();
        }
        
        if (nativeRecurrenceRule.excludedDates.has_value()) {
            cRecurrenceRule.excludedDates = VectorToArrayI64(nativeRecurrenceRule.excludedDates.value());
        }
        if (nativeRecurrenceRule.daysOfWeek.has_value()) {
            cRecurrenceRule.daysOfWeek = VectorToArrayI64(nativeRecurrenceRule.daysOfWeek.value());
        }
        if (nativeRecurrenceRule.daysOfMonth.has_value()) {
            cRecurrenceRule.daysOfMonth = VectorToArrayI64(nativeRecurrenceRule.daysOfMonth.value());
        }
        if (nativeRecurrenceRule.daysOfYear.has_value()) {
            cRecurrenceRule.daysOfYear = VectorToArrayI64(nativeRecurrenceRule.daysOfYear.value());
        }
        if (nativeRecurrenceRule.weeksOfMonth.has_value()) {
            cRecurrenceRule.weeksOfMonth = VectorToArrayI64(nativeRecurrenceRule.weeksOfMonth.value());
        }
        if (nativeRecurrenceRule.weeksOfYear.has_value()) {
            cRecurrenceRule.weeksOfYear = VectorToArrayI64(nativeRecurrenceRule.weeksOfYear.value());
        }
        if (nativeRecurrenceRule.monthsOfYear.has_value()) {
            cRecurrenceRule.monthsOfYear = VectorToArrayI64(nativeRecurrenceRule.monthsOfYear.value());
        }
        return cRecurrenceRule;
    }

    CLocation CJCalendar::BuildCLocation(Location location)
    {
        CLocation clocation;
        if (location.location.has_value()) {
            clocation.location = IMallocCString(location.location.value());
        }
        if (location.longitude.has_value()) {
            clocation.longitude = location.longitude.value();
        }
        if (location.latitude.has_value()) {
            clocation.latitude = location.latitude.value();
        }
        return clocation;
    }

    CArrAttendee CJCalendar::BuildCArrAttendee(vector<Attendee> attendees)
    {
        CArrAttendee arr;
        arr.size = attendees.size();
        arr.head = (CAttendee *)malloc(sizeof(CAttendee) * attendees.size());
        for (int64_t j = 0; j < attendees.size(); j++) {
            arr.head[j].name = IMallocCString(attendees[j].name);
            arr.head[j].email = IMallocCString(attendees[j].email);
            if (attendees[j].role.has_value()) {
                arr.head[j].role = attendees[j].role.value();
            }
        }
        return arr;
    }

    Event CJCalendar::CEventToEvent(CEvent event)
    {
        Event nativeEvent;
        nativeEvent.id = event.id;
        nativeEvent.type = event.type == 0 ? Normal : Important;
        nativeEvent.startTime = event.startTime;
        nativeEvent.endTime = event.endTime;
        nativeEvent.title = std::make_optional<std::string>(event.title);
        nativeEvent.location->location = event.location.location;
        nativeEvent.location->longitude = event.location.longitude;
        nativeEvent.location->latitude = event.location.latitude;
        nativeEvent.isAllDay = std::make_optional<bool>(event.isAllDay);
        for (int64_t i = 0; i < event.attendee.size; i++) {
            Attendee attendee;
            attendee.name = event.attendee.head[i].name;
            attendee.email = event.attendee.head[i].email;
            attendee.role = std::make_optional<RoleType>(RoleType(event.attendee.head[i].role));
            nativeEvent.attendees.push_back(attendee);
        }
        if (event.timeZone != nullptr && strlen(event.timeZone) > 0) {
            nativeEvent.timeZone = std::make_optional<std::string>(event.timeZone);
        }
        std::vector<int> vec;
        for (int64_t i = 0; i < event.reminderTime.size; i++) {
            vec.push_back(static_cast<int>(event.reminderTime.head[i]));
        }
        nativeEvent.reminderTime = vec;
        nativeEvent.recurrenceRule =
            std::make_optional<RecurrenceRule>(BuildNativeRecurrenceRule(event.recurrenceRule));

        if (event.description != nullptr && strlen(event.description) > 0) {
            nativeEvent.description = std::make_optional<std::string>(event.description);
        }
        nativeEvent.service->type = event.service.type;
        nativeEvent.service->uri = event.service.uri;
        if (event.service.description != nullptr && strlen(event.service.description) > 0) {
            nativeEvent.service->description = std::make_optional<std::string>(event.service.description);
        }
        if (event.identifier != nullptr && strlen(event.identifier) > 0) {
            nativeEvent.identifier = std::make_optional<std::string>(event.identifier);
        }
        nativeEvent.isLunar = std::make_optional<bool>(event.isLunar);
        return nativeEvent;
    }

    CEvent CJCalendar::CEventInit()
    {
        CEvent event;
        event.type = 0;
        event.startTime = 0;
        event.endTime = 0;
        event.id = 0;
        event.title = nullptr;
        event.location.location = nullptr;
        event.location.latitude = 0.0;
        event.location.longitude = 0.0;
        event.isAllDay = false;
        event.attendee.size = 0;
        event.attendee.head = nullptr;
        event.timeZone = nullptr;
        event.reminderTime.size = 0;
        event.reminderTime.head = nullptr;
        event.recurrenceRule.recurrenceFrequency = 0;
        event.recurrenceRule.expire = 0;
        event.recurrenceRule.count = 0;
        event.recurrenceRule.interval = 0;
        event.recurrenceRule.excludedDates.size = 0;
        event.recurrenceRule.excludedDates.head = nullptr;
        event.recurrenceRule.daysOfWeek.size = 0;
        event.recurrenceRule.daysOfWeek.head = nullptr;
        event.recurrenceRule.daysOfMonth.size = 0;
        event.recurrenceRule.daysOfMonth.head = nullptr;
        event.recurrenceRule.daysOfYear.size = 0;
        event.recurrenceRule.daysOfYear.head = nullptr;
        event.recurrenceRule.weeksOfMonth.size = 0;
        event.recurrenceRule.weeksOfMonth.head = nullptr;
        event.recurrenceRule.weeksOfYear.size = 0;
        event.recurrenceRule.weeksOfYear.head = nullptr;
        event.recurrenceRule.monthsOfYear.size = 0;
        event.recurrenceRule.monthsOfYear.head = nullptr;
        event.description = nullptr;
        event.service.type = nullptr;
        event.service.uri = nullptr;
        event.service.description = nullptr;
        event.identifier = nullptr;
        event.isLunar = false;
        return event;
    }

    CArrEvents CJCalendar::VectorToCArrEvents(std::vector<Event> events)
    {
        CArrEvents arr;
        arr.size = events.size();
        arr.head = (CEvent *)malloc(sizeof(CEvent) * events.size());
        for (int64_t i = 0; i < events.size(); i++) {
            arr.head[i] = CEventInit();
            arr.head[i].id = static_cast<int64_t>(events[i].id.value());
            arr.head[i].type = events[i].type;
            arr.head[i].startTime = events[i].startTime;
            arr.head[i].endTime = events[i].endTime;
            arr.head[i].title = IMallocCString(events[i].title.value());
            if (events[i].location.has_value()) {
                arr.head[i].location = BuildCLocation(events[i].location.value());
            }
            if (events[i].isAllDay.has_value()) {
                arr.head[i].isAllDay = events[i].isAllDay.value();
            }
            arr.head[i].attendee = BuildCArrAttendee(events[i].attendees);
            if (events[i].timeZone.has_value()) {
                arr.head[i].timeZone = IMallocCString(events[i].timeZone.value());
            }
            if (events[i].reminderTime.has_value() && events[i].reminderTime.value().size() > 0) {
                vector<int> reminderTime = events[i].reminderTime.value();
                arr.head[i].reminderTime.size = reminderTime.size();
                arr.head[i].reminderTime.head = (int64_t *)malloc(sizeof(int64_t) * reminderTime.size());
                for (int64_t j = 0; j < reminderTime.size(); j++) {
                    arr.head[i].reminderTime.head[j] = static_cast<int64_t>(reminderTime[j]);
                }
            }
            if (events[i].recurrenceRule.has_value()) {
                arr.head[i].recurrenceRule = BuildCRecurrenceRule(events[i].recurrenceRule.value());
            }
            if (events[i].description.has_value()) {
                arr.head[i].description = IMallocCString(events[i].description.value());
            }
            if (events[i].service.has_value()) {
                arr.head[i].service.type = IMallocCString(events[i].service.value().type);
                arr.head[i].service.uri = IMallocCString(events[i].service.value().uri);
                if (events[i].service.value().description.has_value()) {
                    arr.head[i].service.description = IMallocCString(events[i].service.value().description.value());
                }
            }
            if (events[i].identifier.has_value()) {
                arr.head[i].identifier = IMallocCString(events[i].identifier.value());
            }
            if (events[i].isLunar.has_value()) {
                arr.head[i].isLunar = events[i].isLunar.value();
            }
        }
        return arr;
    }

    CJCalendar::CJCalendar(std::shared_ptr<Native::CJNativeCalendar> calendar)
    {
        calendar_ = calendar;
    }

    std::shared_ptr<Native::CJNativeCalendar>& CJCalendar::GetNative()
    {
        return calendar_;
    }

    int64_t CJCalendar::AddEvent(CEvent event, int32_t* errcode)
    {
        Event nativeEvent = CEventToEvent(event);
        auto cc = GetNative();
        if (cc == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }
        Native::DumpEvent(nativeEvent);
        int64_t eventId = cc->AddEvent(nativeEvent);
        return eventId;
    }

    void CJCalendar::AddEvents(CArrEvents event, int32_t* errcode)
    {
        std::vector<Event> nativeEvents;
        for (int64_t i = 0; i < event.size; i++) {
            nativeEvents.push_back(CEventToEvent(event.head[i]));
        }
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }
        int count = calendar_->AddEvents(nativeEvents);
        if (count < 0) {
            LOG_ERROR("add events failed");
            *errcode = -1;
        }
    }

    void CJCalendar::DeleteEvent(int64_t eventId, int32_t* errcode)
    {
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }
        bool ret = calendar_->DeleteEvent(eventId);
        if (!ret) {
            LOG_ERROR("delete event failed");
            *errcode = -1;
        }
    }

    void CJCalendar::DeleteEvents(CArrI64 eventIds, int32_t* errcode)
    {
        std::vector<int> ids;
        for (int64_t i = 0; i < eventIds.size; i++) {
            ids.push_back(static_cast<int>(eventIds.head[i]));
        }
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }
        int count = calendar_->DeleteEvents(ids);
        if (count < 0) {
            LOG_ERROR("delete events failed");
            *errcode = -1;
        }
    }

    void CJCalendar::UpdateEvent(CEvent event, int32_t* errcode)
    {
        Event nativeEvent = CEventToEvent(event);
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }
        bool ret = calendar_->UpdateEvent(nativeEvent);
        if (!ret) {
            LOG_ERROR("update event failed");
            *errcode = -1;
        }
    }

    CArrEvents CJCalendar::GetEvents(int64_t eventFilterId, CArrString eventKey, int32_t* errcode)
    {
        std::vector<std::string> keys;
        for (int64_t i = 0; i < eventKey.size; i++) {
            keys.push_back(eventKey.head[i]);
        }
        auto instance = FFIData::GetData<CJEventFilter>(eventFilterId);
        std::shared_ptr<Native::EventFilter> eventFilter = nullptr;
        if (instance!= nullptr && instance->eventFilter_!= nullptr) {
            eventFilter = instance->eventFilter_;
        }
        
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }
        std::vector<Event> events = calendar_->GetEvents(eventFilter, keys);
        CArrEvents arr = VectorToCArrEvents(events);
        return arr;
    }

    CCalendarConfig CJCalendar::GetConfig(int32_t* errcode)
    {
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }
        CalendarConfig nativeConfig = calendar_->GetConfig();
        CCalendarConfig config;
        config.enableReminder = nativeConfig.enableReminder.value();
        config.color = std::get<int64_t>(nativeConfig.color);
        return config;
    }

    void CJCalendar::SetConfig(CCalendarConfig config, int32_t* errcode)
    {
        CalendarConfig nativeConfig;
        nativeConfig.enableReminder = config.enableReminder;
        nativeConfig.color = config.color;
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }

        bool ret = calendar_->SetConfig(nativeConfig);
        if (!ret) {
            LOG_ERROR("set config failed");
            *errcode = -1;
        }
    }

    CCalendarAccount CJCalendar::GetAccount(int32_t* errcode)
    {
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = -1;
        }
        CalendarAccount nativeAccount = calendar_->GetAccount();
        CCalendarAccount account;
        account.name = IMallocCString(nativeAccount.name);
        account.type = IMallocCString(nativeAccount.type);
        account.displayName = IMallocCString(nativeAccount.displayName.value());
        return account;
    }

}
}