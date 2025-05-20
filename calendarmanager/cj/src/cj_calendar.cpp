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
#include "native/ffi_remote_data.h"
#include "ipc_skeleton.h"

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

    char *IMallocCString(const std::string &origin)
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
        nativeEvent.type = event.`type` == 0 ? Normal : Important;
        nativeEvent.startTime = event.startTime;
        nativeEvent.endTime = event.endTime;
        nativeEvent.title = std::to_string(event.title);
        nativeEvent.location.location = std::to_string(event.location.location);
        nativeEvent.location.longitude = event.location.longitude;
        nativeEvent.location.latitude = event.location.latitude;
        nativeEvent.isAllDay = event.isAllDay;
        for (int64_t i = 0; i < event.attendee.size; i++) {
            Attendee attendee;
            attendee.name = std::to_string(event.attendee.head[i].name);
            attendee.email = std::to_string(event.attendee.head[i].email);
            attendee.role = std::to_string(event.attendee.head[i].role);
            nativeEvent.attendees.push_back(attendee);
        }
        nativeEvent.timeZone = std::to_string(event.timeZone)
        nativeEvent.reminderTime = ArrayI64ToVector(event.reminderTime);
        
        nativeEvent.recurrenceRule.recurrenceFrequency = event.recurrenceRule.recurrenceFrequency;
        nativeEvent.recurrenceRule.expire = event.recurrenceRule.expire;
        nativeEvent.recurrenceRule.count = event.recurrenceRule.count;
        nativeEvent.recurrenceRule.interval = event.recurrenceRule.interval;
        nativeEvent.recurrenceRule.excludedDates = ArrayI64ToVector(event.recurrenceRule.excludedDates);
        nativeEvent.recurrenceRule.daysOfWeek = ArrayI64ToVector(event.recurrenceRule.daysOfWeek);
        nativeEvent.recurrenceRule.daysOfMonth = ArrayI64ToVector(event.recurrenceRule.daysOfMonth);
        nativeEvent.recurrenceRule.daysOfYear = ArrayI64ToVector(event.recurrenceRule.daysOfYear);
        nativeEvent.recurrenceRule.weeksOfMonth = ArrayI64ToVector(event.recurrenceRule.weeksOfMonth);
        nativeEvent.recurrenceRule.weeksOfYear = ArrayI64ToVector(event.recurrenceRule.weeksOfYear);
        nativeEvent.recurrenceRule.monthsOfYear = ArrayI64ToVector(event.recurrenceRule.monthsOfYear);

        nativeEvent.description = std::to_string(event.description);
        nativeEvent.service.`type` = std::to_string(event.service.`type`);
        nativeEvent.service.uri = std::to_string(event.service.uri);
        nativeEvent.service.description = std::to_string(event.service.description);
        nativeEvent.identifier = std::to_string(event.identifier);
        nativeEvent.isLunar = event.isLunar;
        return nativeEvent;
    }



    int64_t CJCalendar::AddEvent(CEvent event, int32_t* errcode)
    {
        Event nativeEvent = CEventToEvent(event);
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }
        int64_t eventId = calendar_->AddEvent(nativeEvent);
        return eventId;
    }

    void CJCalendar::AddEvents(CArrEvents event, int32_t* errcode)
    {
        std::vector<Event> nativeEvents;
        for (int64_t i = 0; i < event.size; i++) {
            nativeEvents.push_back(CEventToEvent(event.head[i]));
        }
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }
        int count = calendar_->AddEvents(nativeEvents);
        if (count < 0)
        {
            HILOG_ERROR("add events failed");
            errcode = -1;
        }
    }

    void CJCalendar::DeleteEvent(int64_t eventId, int32_t* errcode)
    {
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }
        bool ret = calendar_->DeleteEvent(eventId);
        if (!ret) {
            HILOG_ERROR("delete event failed");
            errcode = -1;
        }
    }

    void CJCalendar::DeleteEvents(CArrI64 eventIds, int32_t* errcode)
    {
        std::vector<int64_t> ids;
        for (int64_t i = 0; i < eventIds.size; i++) {
            ids.push_back(eventIds.head[i]);
        }
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }
        int count = calendar_->DeleteEvents(ids);
        if (count < 0) {
            HILOG_ERROR("delete events failed");
            errcode = -1;
        }
    }

    void CJCalendar::UpdateEvent(CEvent event, int32_t* errcode)
    {
        Event nativeEvent = CEventToEvent(event);
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }
        bool ret = calendar_->UpdateEvent(nativeEvent);
        if (!ret) {
            HILOG_ERROR("update event failed");
            errcode = -1;
        }
    }

    CArrEvents CJCalendar::GetEvents(int64_t eventFilterId, CArrString eventKey, int32_t* errcode)
    {
        std::vector<std::string> keys;
        for (int64_t i = 0; i < eventKey.size; i++) {
            keys.push_back(eventKey.head[i]);
        }
        auto instance = FFIData::GetData<CJEventFilter>(eventFilterId);
        if (instance == nullptr) {
            HILOG_ERROR("CJEventFilter is nullptr");
            errcode = -1;
        }
        auto eventFilter = instance->eventFilter_;
        if (eventFilter == nullptr) {
            HILOG_ERROR("eventFilter is nullptr");
            errcode = -1;
        }
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }
        std::vector<Event> events = calendar_->GetEvents(eventFilter, keys);
        CArrEvents arr;
        arr.size = events.size();
        arr.head = (CEvent *)malloc(sizeof(CEvent) * events.size());
        for (int64_t i = 0; i < events.size(); i++) {
            arr.head[i].id = events[i].id;
            arr.head[i].`type` = events[i].type;
            arr.head[i].startTime = events[i].startTime;
            arr.head[i].endTime = events[i].endTime;
            arr.head[i].title = IMallocCString(events[i].title);
            arr.head[i].location.location = IMallocCString(events[i].location.location);
            arr.head[i].location.longitude = events[i].location.longitude;
            arr.head[i].location.latitude = events[i].location.latitude;
            arr.head[i].isAllDay = events[i].isAllDay;
            arr.head[i].attendee.size = events[i].attendees.size();
            arr.head[i].attendee.head = (CAttendee *)malloc(sizeof(CAttendee) * events[i].attendees.size());
            for (int64_t j = 0; j < events[i].attendees.size(); j++) {
                arr.head[i].attendee.head[j].name = IMallocCString(events[i].attendees[j].name);
                arr.head[i].attendee.head[j].email = IMallocCString(events[i].attendees[j].email);
                arr.head[i].attendee.head[j].role = IMallocCString(events[i].attendees[j].role);
            }
            arr.head[i].timeZone = IMallocCString(events[i].timeZone);
            arr.head[i].reminderTime.size = events[i].reminderTime.size();
            arr.head[i].reminderTime.head = (int64_t *)malloc(sizeof(int64_t) * events[i].reminderTime.size());
            for (int64_t j = 0; j < events[i].reminderTime.size(); j++) {
                arr.head[i].reminderTime.head[j] = events[i].reminderTime[j];
            }
            arr.head[i].recurrenceRule.recurrenceFrequency = events[i].recurrenceRule.recurrenceFrequency;
            arr.head[i].recurrenceRule.expire = events[i].recurrenceRule.expire;
            arr.head[i].recurrenceRule.count = events[i].recurrenceRule.count;
            arr.head[i].recurrenceRule.interval = events[i].recurrenceRule.interval;
            arr.head[i].recurrenceRule.excludedDates.size = events[i].recurrenceRule.excludedDates.size();
            arr.head[i].recurrenceRule.excludedDates.head = (int64_t *)malloc(sizeof(int64_t) * events[i].recurrenceRule.excludedDates.size());
            for (int64_t j = 0; j < events[i].recurrenceRule.excludedDates.size(); j++) {
                arr.head[i].recurrenceRule.excludedDates.head[j] = events[i].recurrenceRule.excludedDates[j];
            }
            arr.head[i].recurrenceRule.daysOfWeek.size = events[i].recurrenceRule.daysOfWeek.size();
            arr.head[i].recurrenceRule.daysOfWeek.head = (int64_t *)malloc(sizeof(int64_t) * events[i].recurrenceRule.daysOfWeek.size());
            for (int64_t j = 0; j < events[i].recurrenceRule.daysOfWeek.size(); j++) {
                arr.head[i].recurrenceRule.daysOfWeek.head[j] = events[i].recurrenceRule.daysOfWeek[j];
            }
            arr.head[i].recurrenceRule.daysOfMonth.size = events[i].recurrenceRule.daysOfMonth.size();
            arr.head[i].recurrenceRule.daysOfMonth.head = (int64_t *)malloc(sizeof(int64_t) * events[i].recurrenceRule.daysOfMonth.size());
            for (int64_t j = 0; j < events[i].recurrenceRule.daysOfMonth.size(); j++) {
                arr.head[i].recurrenceRule.daysOfMonth.head[j] = events[i].recurrenceRule.daysOfMonth[j];
            }
            arr.head[i].recurrenceRule.daysOfYear.size = events[i].recurrenceRule.daysOfYear.size();
            arr.head[i].recurrenceRule.daysOfYear.head = (int64_t *)malloc(sizeof(int64_t) * events[i].recurrenceRule.daysOfYear.size());
            for (int64_t j = 0; j < events[i].recurrenceRule.daysOfYear.size(); j++) {
                arr.head[i].recurrenceRule.daysOfYear.head[j] = events[i].recurrenceRule.daysOfYear[j];
            }
            arr.head[i].recurrenceRule.weeksOfMonth.size = events[i].recurrenceRule.weeksOfMonth.size();
            arr.head[i].recurrenceRule.weeksOfMonth.head = (int64_t *)malloc(sizeof(int64_t) * events[i].recurrenceRule.weeksOfMonth.size());
            for (int64_t j = 0; j < events[i].recurrenceRule.weeksOfMonth.size(); j++) {
                arr.head[i].recurrenceRule.weeksOfMonth.head[j] = events[i].recurrenceRule.weeksOfMonth[j];
            }
            arr.head[i].recurrenceRule.weeksOfYear.size = events[i].recurrenceRule.weeksOfYear.size();
            arr.head[i].recurrenceRule.weeksOfYear.head = (int64_t *)malloc(sizeof(int64_t) * events[i].recurrenceRule.weeksOfYear.size());
            for (int64_t j = 0; j < events[i].recurrenceRule.weeksOfYear.size(); j++) {
                arr.head[i].recurrenceRule.weeksOfYear.head[j] = events[i].recurrenceRule.weeksOfYear[j];
            }
            arr.head[i].recurrenceRule.monthsOfYear.size = events[i].recurrenceRule.monthsOfYear.size();
            arr.head[i].recurrenceRule.monthsOfYear.head = (int64_t *)malloc(sizeof(int64_t) * events[i].recurrenceRule.monthsOfYear.size());
            for (int64_t j = 0; j < events[i].recurrenceRule.monthsOfYear.size(); j++) {
                arr.head[i].recurrenceRule.monthsOfYear.head[j] = events[i].recurrenceRule.monthsOfYear[j];
            }
            arr.head[i].description = IMallocCString(events[i].description);
            arr.head[i].service.`type` = IMallocCString(events[i].service.`type`);
            arr.head[i].service.uri = IMallocCString(events[i].service.uri);
            arr.head[i].service.description = IMallocCString(events[i].service.description);
            arr.head[i].identifier = IMallocCString(events[i].identifier);
            arr.head[i].isLunar = events[i].isLunar;
        }
        return arr;
    }

    CCalendarConfig CJCalendar::GetConfig(int32_t* errcode)
    {
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }
        CalendarConfig nativeConfig = calendar_->GetConfig();
        CCalendarConfig config;
        config.enableReminder = nativeConfig.enableReminder;
        config.color = nativeConfig.color;
        return config;
    }

    void CJCalendar::SetConfig(CCalendarConfig config, int32_t* errcode)
    {
        CalendarConfig nativeConfig;
        nativeConfig.enableReminder = config.enableReminder;
        nativeConfig.color = config.color;
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }

        bool ret = calendar_->SetConfig(nativeConfig);
        if (!ret) {
            HILOG_ERROR("set config failed");
            errcode = -1;
        }
    }

    CCalendarAccount CJCalendar::GetAccount(int32_t* errcode)
    {
        if (calendar_ == nullptr) {
            HILOG_ERROR("calendar_ is nullptr");
            errcode = -1;
        }
        CalendarAccount nativeAccount = calendar_->GetAccount();
        CCalendarAccount account;
        account.name = IMallocCString(nativeAccount.name);
        account.`type` = IMallocCString(nativeAccount.type);
        account.displayName = IMallocCString(nativeAccount.displayName);
        return account;
    }

}
}