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
#ifndef CALENDAR_MANAGER_FFI_H
#define CALENDAR_MANAGER_FFI_H
#include <cstdint>
#include <string>
#include <vector>
#include "cj_common_ffi.h"
#include "ffi_remote_data.h"
#include "native_util.h"

extern "C" {
struct CCalendarAccount {
    char* name;
    char* type;
    char* displayName;
};

struct CLocation {
    char* location;
    double longitude;
    double latitude;
};

struct CAttendee {
    char* name;
    char* email;
    int64_t role;
};

struct CArrAttendee {
    CAttendee* head;
    int64_t size;
};

struct CRecurrenceRule {
    int64_t recurrenceFrequency;
    int64_t expire;
    int64_t count;
    int64_t interval;
    CArrI64 excludedDates;
    CArrI64 daysOfWeek;
    CArrI64 daysOfMonth ;
    CArrI64 daysOfYear;
    CArrI64 weeksOfMonth;
    CArrI64 weeksOfYear;
    CArrI64 monthsOfYear;
};

struct CEventService {
    char* type;
    char* uri;
    char* description;
};

struct CEvent {
    int64_t type;
    int64_t startTime;
    int64_t endTime;
    int64_t id;
    char* title;
    CLocation location;
    bool isAllDay;
    CArrAttendee attendee;
    char* timeZone;
    CArrI64 reminderTime;
    CRecurrenceRule recurrenceRule;
    char* description;
    CEventService service;
    char* identifier;
    bool isLunar;
};

struct CArrEvents {
    CEvent* head;
    int64_t size;
};

struct CCalendarConfig {
    bool enableReminder;
    int64_t color;
};

// calendar manager
FFI_EXPORT void FfiOHOSGetCalendarManager(int64_t contextId, int32_t* errcode);
FFI_EXPORT int64_t FfiOHOSCalendarManagerCreateCalendar(CCalendarAccount calendarAccount, int64_t* calendarId, int32_t* errcode);
FFI_EXPORT void FfiOHOSCalendarManagerdeleteCalendar(int64_t calendarId, int32_t* errcode);
FFI_EXPORT int64_t FfiOHOSCalendarManagerGetCalendar(CCalendarAccount calendarAccount, int64_t* calendarId, int32_t* errcode);
FFI_EXPORT CArrI64 FfiOHOSCalendarManagerGetAllCalendars(int32_t* errcode);
FFI_EXPORT int64_t FfiOHOSCalendarManagerEditerEvent(char* eventstr, int32_t* errcode);
// calendar
FFI_EXPORT int64_t FfiOHOSCalendarAddEvent(int64_t id, CEvent event, int32_t* errcode);
FFI_EXPORT void FfiOHOSCalendarAddEvents(int64_t id, CArrEvents event, int32_t* errcode);
FFI_EXPORT void FfiOHOSCalendarDeleteEvent(int64_t id, int64_t eventId, int32_t* errcode);
FFI_EXPORT void FfiOHOSCalendarDeleteEvents(int64_t id, CArrI64 eventIds, int32_t* errcode);
FFI_EXPORT void FfiOHOSCalendarUpdateEvent(int64_t id, CEvent event, int32_t* errcode);
FFI_EXPORT CArrEvents FfiOHOSCalendarGetEvents(int64_t id, int64_t eventFilterId, CArrString eventKey, int32_t* errcode);
FFI_EXPORT CCalendarConfig FfiOHOSCalendarGetConfig(int64_t id, int32_t* errcode);
FFI_EXPORT void FfiOHOSCalendarSetConfig(int64_t id, CCalendarConfig cCalendarConfig, int32_t* errcode);
FFI_EXPORT CCalendarAccount FfiOHOSCalendarGetAccount(int64_t id, int32_t* errcode);
//event filter
FFI_EXPORT int64_t FfiOHOSEventFilterFilterById(CArrI64 idsCArr, int32_t* errcode);
FFI_EXPORT int64_t FfiOHOSEventFilterFilterByTime(int64_t startTime, int64_t end, int32_t* errcode);
FFI_EXPORT int64_t FfiOHOSEventFilterFilterByTitle(char* title, int32_t* errcode);
}

#endif