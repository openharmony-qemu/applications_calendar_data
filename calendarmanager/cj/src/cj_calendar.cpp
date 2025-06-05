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

    CArrI64 VectorToCArrI64(const std::vector<int64_t> &vec)
    {
        CArrI64 arr;
        arr.size = vec.size();
        arr.head = (int64_t *)malloc(sizeof(int64_t) * vec.size());
        for (int64_t i = 0; i < arr.size(); i++) {
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
        
        nativeEvent.recurrenceRule->recurrenceFrequency = RecurrenceType(event.recurrenceRule.recurrenceFrequency);
        nativeEvent.recurrenceRule->expire = std::make_optional<int64_t>(event.recurrenceRule.expire);
        nativeEvent.recurrenceRule->count = std::make_optional<int64_t>(event.recurrenceRule.count);
        nativeEvent.recurrenceRule->interval = std::make_optional<int64_t>(event.recurrenceRule.interval);
        nativeEvent.recurrenceRule->excludedDates = std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(event.recurrenceRule.excludedDates));
        nativeEvent.recurrenceRule->daysOfWeek = std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(event.recurrenceRule.daysOfWeek));
        nativeEvent.recurrenceRule->daysOfMonth = std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(event.recurrenceRule.daysOfMonth));
        nativeEvent.recurrenceRule->daysOfYear = std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(event.recurrenceRule.daysOfYear));
        nativeEvent.recurrenceRule->weeksOfMonth = std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(event.recurrenceRule.weeksOfMonth));
        nativeEvent.recurrenceRule->weeksOfYear = std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(event.recurrenceRule.weeksOfYear));
        nativeEvent.recurrenceRule->monthsOfYear = std::make_optional<std::vector<int64_t>>(ArrayI64ToVector(event.recurrenceRule.monthsOfYear));

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
        native::DumpEvent(nativeEvent);
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
        CArrEvents arr;
        arr.size = events.size();
        arr.head = (CEvent *)malloc(sizeof(CEvent) * events.size());
        for (int64_t i = 0; i < events.size(); i++) {
            arr.head[i].id = static_cast<int64_t>(events[i].id.value());
            arr.head[i].type = events[i].type;
            arr.head[i].startTime = events[i].startTime;
            arr.head[i].endTime = events[i].endTime;
            arr.head[i].title = IMallocCString(events[i].title.value());
            if (events[i].location.has_value()) {
                Location location = events[i].location.value();
                if (location.location.has_value()) {
                    arr.head[i].location.location = IMallocCString(location.location.value());
                }
                if (location.longitude.has_value()) {
                    arr.head[i].location.longitude = location.longitude.value();
                }
                if (location.latitude.has_value()) {
                    arr.head[i].location.latitude = location.latitude.value();
                }
            }
            
            if (events[i].isAllDay.has_value()) {
                arr.head[i].isAllDay = events[i].isAllDay.value();
            }
            arr.head[i].attendee.size = events[i].attendees.size();
            arr.head[i].attendee.head = (CAttendee *)malloc(sizeof(CAttendee) * events[i].attendees.size());
            for (int64_t j = 0; j < events[i].attendees.size(); j++) {
                arr.head[i].attendee.head[j].name = IMallocCString(events[i].attendees[j].name);
                arr.head[i].attendee.head[j].email = IMallocCString(events[i].attendees[j].email);
                if (events[i].attendees[j].role.has_value()) {
                    arr.head[i].attendee.head[j].role = IMallocCString(events[i].attendees[j].role.value());
                }
            }
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
            
            arr.head[i].recurrenceRule.recurrenceFrequency = events[i].recurrenceRule->recurrenceFrequency;
            if (events[i].recurrenceRule->expire.has_value()) {
                arr.head[i].recurrenceRule.expire = IMallocCString(events[i].recurrenceRule->expire.value());
            }
            if (events[i].recurrenceRule->count.has_value()) {
                arr.head[i].recurrenceRule.count = events[i].recurrenceRule->count.value();
            }
            if (events[i].recurrenceRule->interval.has_value()) {
                arr.head[i].recurrenceRule.interval = events[i].recurrenceRule->interval.value();
            }
            
            if (events[i].recurrenceRule->excludedDates.has_value()) {
                arr.head[i].recurrenceRule.excludedDates = VectorToArrayI64(events[i].recurrenceRule->excludedDates.value())
            }
            if (events[i].recurrenceRule->daysOfWeek.has_value()) {
                arr.head[i].recurrenceRule.daysOfWeek = VectorToArrayI64(events[i].recurrenceRule->daysOfWeek.value())
            }
            if (events[i].recurrenceRule->daysOfMonth.has_value()) {
                arr.head[i].recurrenceRule.daysOfMonth = VectorToArrayI64(events[i].recurrenceRule->daysOfMonth.value())
            }
            if (events[i].recurrenceRule->daysOfYear.has_value()) {
                arr.head[i].recurrenceRule.daysOfYear = VectorToArrayI64(events[i].recurrenceRule->daysOfYear.value())
            }
            if (events[i].recurrenceRule->weeksOfMonth.has_value()) {
                arr.head[i].recurrenceRule.weeksOfMonth = VectorToArrayI64(events[i].recurrenceRule->weeksOfMonth.value())
            }
            if (events[i].recurrenceRule->weeksOfYear.has_value()) {
                arr.head[i].recurrenceRule.weeksOfYear = VectorToArrayI64(events[i].recurrenceRule->weeksOfYear.value())
            }
            if (events[i].recurrenceRule->monthsOfYear.has_value()) {
                arr.head[i].recurrenceRule.monthsOfYear = VectorToArrayI64(events[i].recurrenceRule->monthsOfYear.value())
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