/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

#ifndef CALENDAR_DEFINE_H
#define CALENDAR_DEFINE_H
#include <string>
#include <string_view>
#include <vector>
#include <optional>
#include <variant>

using std::string;
using std::string_view;
using std::vector;
using std::optional;
using std::variant;

namespace OHOS::CalendarApi {

struct CalendarAccount {
    std::string name;  // readonly
    std::string type;
    optional<string> displayName;
};


enum EventType {
    Normal = 0,
    Important = 1
};

struct Location {
    optional<string> location;
    optional<double> longitude;
    optional<double> latitude;

    bool operator==(const Location& other) const
    {
        return location == other.location && longitude == other.longitude && latitude == other.latitude;
    }
};

enum RoleType  {
    NONE = 0,
    PARTICIPANT = 1,
    ORGANIZER = 2,
};

struct Attendee {
    string name;
    string email;
    optional<RoleType> role;
    bool operator==(const Attendee& other) const
    {
        return name == other.name && email == other.email && role.value_or(NONE) == other.role.value_or(NONE);
    }
};

enum RecurrenceType {
    YEARLY = 0,
    MONTHLY = 1,
    WEEKLY = 2,
    DAILY = 3,
};

struct RecurrenceRule {
    RecurrenceType recurrenceFrequency;
    optional<bool> enable;
    optional<int64_t> expire;
    optional<int64_t> count;
    optional<int64_t> interval;
    optional<vector<int64_t>> excludedDates;
};

struct EventService {
    string type;
    string uri;
    optional<string> description;
};

struct Event {
    optional<int> id;
    EventType type;
    optional<Location> location;
    optional<string> title;
    int64_t startTime;
    int64_t endTime;
    optional<bool> isAllDay;
    vector<Attendee> attendees;
    optional<string> timeZone;
    optional<vector<int>> reminderTime;
    optional<RecurrenceRule> recurrenceRule;
    optional<string> description;
    optional<EventService> service;
    optional<string> identifier;
};


struct CalendarConfig {
    optional<bool> enableReminder;
    variant<string, int64_t> color;
    bool operator==(const CalendarConfig& other) const
    {
        return enableReminder == other.enableReminder && color == other.color;
    }
};

}  // namespace OHOS::CalendarApi


#endif