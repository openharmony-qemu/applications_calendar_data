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

    CArrI64 VectorToArrayI64(const std::vector<int64_t> &vec, int32_t* errcode)
    {
        CArrI64 arr = {};
        arr.size = static_cast<int64_t>(vec.size());
        if (arr.size == 0 || arr.size > (SIZE_MAX * sizeof(int64_t))) {
            return arr;
        }
        arr.head = static_cast<int64_t *>(malloc(sizeof(int64_t) * arr.size));
        if (arr.head == nullptr) {
            *errcode = CJ_ERR_OUT_OF_MEMORY;
            LOG_ERROR("CArrI64 malloc failed");
            return arr;
        }
        for (size_t i = 0; i < vec.size(); i++) {
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
        if (length > (SIZE_MAX * sizeof(char))) {
            return nullptr;
        }
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

    CRecurrenceRule CJCalendar::BuildCRecurrenceRule(RecurrenceRule nativeRecurrenceRule, int32_t* errcode)
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
            cRecurrenceRule.excludedDates = VectorToArrayI64(nativeRecurrenceRule.excludedDates.value(), errcode);
        }
        if (nativeRecurrenceRule.daysOfWeek.has_value()) {
            cRecurrenceRule.daysOfWeek = VectorToArrayI64(nativeRecurrenceRule.daysOfWeek.value(), errcode);
        }
        if (nativeRecurrenceRule.daysOfMonth.has_value()) {
            cRecurrenceRule.daysOfMonth = VectorToArrayI64(nativeRecurrenceRule.daysOfMonth.value(), errcode);
        }
        if (nativeRecurrenceRule.daysOfYear.has_value()) {
            cRecurrenceRule.daysOfYear = VectorToArrayI64(nativeRecurrenceRule.daysOfYear.value(), errcode);
        }
        if (nativeRecurrenceRule.weeksOfMonth.has_value()) {
            cRecurrenceRule.weeksOfMonth = VectorToArrayI64(nativeRecurrenceRule.weeksOfMonth.value(), errcode);
        }
        if (nativeRecurrenceRule.weeksOfYear.has_value()) {
            cRecurrenceRule.weeksOfYear = VectorToArrayI64(nativeRecurrenceRule.weeksOfYear.value(), errcode);
        }
        if (nativeRecurrenceRule.monthsOfYear.has_value()) {
            cRecurrenceRule.monthsOfYear = VectorToArrayI64(nativeRecurrenceRule.monthsOfYear.value(), errcode);
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

    CArrAttendee CJCalendar::BuildCArrAttendee(vector<Attendee> attendees, int32_t* errcode)
    {
        CArrAttendee arr = {};
        arr.size = static_cast<int64_t>(attendees.size());
        if (arr.size == 0 || arr.size > (SIZE_MAX * sizeof(CAttendee))) {
            LOG_ERROR("Invalid size for memory allocation");
            *errcode = CJ_ERR_OUT_OF_MEMORY;
            return arr;
        }
        arr.head = static_cast<CAttendee *>(malloc(sizeof(CAttendee) * arr.size));
        if (arr.head == nullptr) {
            *errcode = CJ_ERR_OUT_OF_MEMORY;
            LOG_ERROR("CAttendee malloc failed");
            return arr;
        }
        for (size_t j = 0; j < attendees.size(); j++) {
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
        Event nativeEvent = {};
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

    void CJCalendar::CRecurrenceRuleFree(CRecurrenceRule cRecurrenceRule)
    {
        if (cRecurrenceRule.excludedDates.head != nullptr) {
            free(cRecurrenceRule.excludedDates.head);
        }
        if (cRecurrenceRule.daysOfWeek.head != nullptr) {
            free(cRecurrenceRule.daysOfWeek.head);
        }
        if (cRecurrenceRule.daysOfMonth.head != nullptr) {
            free(cRecurrenceRule.daysOfMonth.head);
        }
        if (cRecurrenceRule.daysOfYear.head != nullptr) {
            free(cRecurrenceRule.daysOfYear.head);
        }
        if (cRecurrenceRule.weeksOfMonth.head != nullptr) {
            free(cRecurrenceRule.weeksOfMonth.head);
        }
        if (cRecurrenceRule.weeksOfYear.head != nullptr) {
            free(cRecurrenceRule.weeksOfYear.head);
        }
        if (cRecurrenceRule.monthsOfYear.head != nullptr) {
            free(cRecurrenceRule.monthsOfYear.head);
        }
    }

    void CJCalendar::CArrAttendeeFree(CArrAttendee cArrAttendee)
    {
        for (int64_t j = 0; j < cArrAttendee.size; j++) {
            if (cArrAttendee.head[j].name!= nullptr) {
                free(cArrAttendee.head[j].name);
            }
            if (cArrAttendee.head[j].email!= nullptr) {
                free(cArrAttendee.head[j].email);
            }
        }
    }

    void CJCalendar::CArrEventfree(CArrEvents arr)
    {
        if (arr.head == nullptr) {
            return;
        }
        for (int64_t i = 0; i < arr.size; i++) {
            if (arr.head[i].title != nullptr) {
                free(arr.head[i].title);
            }
            if (arr.head[i].timeZone != nullptr) {
                free(arr.head[i].timeZone);
            }
            if (arr.head[i].description != nullptr) {
                free(arr.head[i].description);
            }
            if (arr.head[i].service.description != nullptr) {
                free(arr.head[i].service.description);
            }
            if (arr.head[i].service.type != nullptr) {
                free(arr.head[i].service.type);
            }
            if (arr.head[i].service.uri != nullptr) {
                free(arr.head[i].service.uri);
            }
            if (arr.head[i].identifier != nullptr) {
                free(arr.head[i].identifier);
            }
            if (arr.head[i].reminderTime.head != nullptr) {
                free(arr.head[i].reminderTime.head);
            }
            if (arr.head[i].attendee.head != nullptr) {
                CArrAttendeeFree(arr.head[i].attendee);
                free(arr.head[i].attendee.head);
            }
            if (arr.head[i].location.location != nullptr) {
                free(arr.head[i].location.location);
            }
            CRecurrenceRuleFree(arr.head[i].recurrenceRule);
            free(&arr.head[i]);
        }
    }

    void CJCalendar::EventToCArrEvent(CEvent& cevent, Event& event, int32_t* errcode)
    {
        cevent.id = static_cast<int64_t>(event.id.value());
        cevent.type = event.type;
        cevent.startTime = event.startTime;
        cevent.endTime = event.endTime;
        cevent.title = IMallocCString(event.title.value_or(""));
        if (event.location.has_value()) {
            cevent.location = BuildCLocation(event.location.value());
        }
        cevent.isAllDay = event.isAllDay.value_or(false);
        cevent.attendee = BuildCArrAttendee(event.attendees, errcode);
        cevent.timeZone = IMallocCString(event.timeZone.value_or(""));
        if (event.reminderTime.has_value() && event.reminderTime.value().size() > 0) {
            vector<int> reminderTime = event.reminderTime.value();
            cevent.reminderTime.size = static_cast<int64_t>(reminderTime.size());
            cevent.reminderTime.head = static_cast<int64_t *>(malloc(sizeof(int64_t) * reminderTime.size()));
            if (cevent.reminderTime.head == nullptr) {
                *errcode = CJ_ERR_OUT_OF_MEMORY;
                return;
            }
            for (int64_t j = 0; j < cevent.reminderTime.size; j++) {
                cevent.reminderTime.head[j] = static_cast<int64_t>(reminderTime[j]);
            }
        }
        if (event.recurrenceRule.has_value()) {
            cevent.recurrenceRule = BuildCRecurrenceRule(event.recurrenceRule.value(), errcode);
        }
        cevent.description = IMallocCString(event.description.value_or(""));
        if (event.service.has_value()) {
            cevent.service.type = IMallocCString(event.service.value().type);
            cevent.service.uri = IMallocCString(event.service.value().uri);
            cevent.service.description = IMallocCString(event.service.value().description.value_or(""));
        }
        cevent.identifier = IMallocCString(event.identifier.value_or(""));
        cevent.isLunar = event.isLunar.value_or(false);
    }

    CArrEvents CJCalendar::VectorToCArrEvents(std::vector<Event> &events, int32_t* errcode)
    {
        CArrEvents arr = {};
        if (events.size() == 0 || events.size() > (SIZE_MAX * sizeof(CEvent))) {
            LOG_ERROR("events.size() is error");
            return arr;
        }
        arr.head = static_cast<CEvent *>(malloc(sizeof(CEvent) * events.size()));
        if (arr.head == nullptr) {
            *errcode = CJ_ERR_OUT_OF_MEMORY;
            return arr;
        }
        arr.size = static_cast<int64_t>(events.size());
        for (size_t i = 0; i < events.size(); i++) {
            memset_s(&arr.head[i], sizeof(arr.head[i]), 0, sizeof(arr.head[i]));
            EventToCArrEvent(arr.head[i], events[i], errcode);
            if (*errcode != CJ_OK) {
                LOG_ERROR("Event To CArrEvent failed.");
                return arr;
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
        auto cnative = GetNative();
        if (cnative == nullptr) {
            LOG_ERROR("cnative is nullptr");
            *errcode = CJ_ERR_NULL_PTR;
            return -1;
        }
        Native::DumpEvent(nativeEvent);
        int64_t eventId = cnative->AddEvent(nativeEvent);
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
            *errcode = CJ_ERR_NULL_PTR;
            return;
        }
        int count = calendar_->AddEvents(nativeEvents);
        if (count < 0) {
            LOG_ERROR("add events failed");
            *errcode = CJ_ERR_NULL_PTR;
            return;
        }
    }

    void CJCalendar::DeleteEvent(int64_t eventId, int32_t* errcode)
    {
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = CJ_ERR_NULL_PTR;
            return;
        }
        bool ret = calendar_->DeleteEvent(eventId);
        if (!ret) {
            LOG_ERROR("delete event failed");
            *errcode = CJ_ERR_NULL_PTR;
            return;
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
            *errcode = CJ_ERR_NULL_PTR;
            return;
        }
        int count = calendar_->DeleteEvents(ids);
        if (count < 0) {
            LOG_ERROR("delete events failed");
            *errcode = CJ_ERR_NULL_PTR;
            return;
        }
    }

    void CJCalendar::UpdateEvent(CEvent event, int32_t* errcode)
    {
        Event nativeEvent = CEventToEvent(event);
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = CJ_ERR_NULL_PTR;
            return;
        }
        bool ret = calendar_->UpdateEvent(nativeEvent);
        if (!ret) {
            LOG_ERROR("update event failed");
            *errcode = CJ_ERR_NULL_PTR;
            return;
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
        CArrEvents arr = {};
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = CJ_ERR_NULL_PTR;
            return arr;
        }
        std::vector<Event> events = calendar_->GetEvents(eventFilter, keys);
        arr = VectorToCArrEvents(events, errcode);
        if (*errcode != 0) {
            CArrEventfree(arr);
        }
        return arr;
    }

    CCalendarConfig CJCalendar::GetConfig(int32_t* errcode)
    {
        CCalendarConfig config = {};
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = CJ_ERR_NULL_PTR;
            return config;
        }
        CalendarConfig nativeConfig = calendar_->GetConfig();
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
            *errcode = CJ_ERR_NULL_PTR;
            return;
        }

        bool ret = calendar_->SetConfig(nativeConfig);
        if (!ret) {
            LOG_ERROR("set config failed");
            *errcode = CJ_ERR_NULL_PTR;
            return;
        }
    }

    CCalendarAccount CJCalendar::GetAccount(int32_t* errcode)
    {
        CCalendarAccount account;
        if (calendar_ == nullptr) {
            LOG_ERROR("calendar_ is nullptr");
            *errcode = CJ_ERR_NULL_PTR;
            return account;
        }
        CalendarAccount nativeAccount = calendar_->GetAccount();
        account.name = IMallocCString(nativeAccount.name);
        account.type = IMallocCString(nativeAccount.type);
        account.displayName = IMallocCString(nativeAccount.displayName.value());
        return account;
    }
}
}