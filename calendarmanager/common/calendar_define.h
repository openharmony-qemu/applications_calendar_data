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

using std::string;
using std::string_view;
using std::vector;
using std::optional;

namespace OHOS::CalendarApi {

struct CalendarAccount {
    std::string name;  // readonly
    std::string type;
    optional<string> displayName;
};


enum EventType : uint32_t {
    Normal = 0,
    Important = 1
};


struct Location {
public:
    optional<string> location;
    optional<int> longitude;
    optional<int> latitude;
};

struct Attendee {
    string name;
    string email;
    bool operator==(const Attendee& other) const
    {
        return name == other.name && email == other.email;
    }
};

enum RecurrenceType {
    YEAR = 0,
    MONTH = 1,
    WEEK = 2,
    DAY = 3,
};

struct RecurrenceRule {
    RecurrenceType recurrenceType;
    optional<bool> enable;
    optional<int> expire;
};

struct EventService {
public:
    optional<string> description;
    optional<string> type;
    string uri;
};

struct Event {
    optional<int> id;
    EventType type;
    optional<Location> location;
    optional<string> title;
    int64_t start;
    int64_t end;
    optional<bool> isAllDay;
    vector<Attendee> attendees;
    optional<string> timeZone;
    optional<vector<int>> remind;
    optional<RecurrenceRule> recurrenceRule;
    optional<string> description;
    optional<EventService> service;
};


struct CalendarConfig {
    optional<bool> enableRemind;
    optional<string> color;
    bool operator==(const CalendarConfig& other) const
    {
        return enableRemind == other.enableRemind && color == other.color;
    }
};

}  // namespace OHOS::CalendarApi


#endif