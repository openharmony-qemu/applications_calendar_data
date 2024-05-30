/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

#include "native_calendar.h"
#include "data_share_helper_manager.h"
#include "calendar_log.h"
#include "calendar_env.h"
#include "data_ability_helper.h"
#include "native_util.h"

namespace {
    const string eventUrl = "datashare:///calendardata/Events";
    const string attendeeUrl = "datashare:///calendardata/Attendees";
    const string calendarUrl = "datashare:///calendardata/Calendars";
    const string reminderUrl = "datashare:///calendardata/Reminders";
}
namespace OHOS::CalendarApi::Native {
Calendar::Calendar(int id)
    : m_id(id)
{
    uint64_t tokenId = CalendarEnv::GetInstance().GetTokenId();
    auto bumdleName = CalendarEnv::GetInstance().GetBundleName();
    auto bundleName_tokeId = "?bundleName=" + bumdleName + "&tokenId=" + std::to_string(tokenId);
    LOG_INFO("bundleName_tokeId: %{public}s", bundleName_tokeId.c_str());
    m_eventUri = std::make_unique<Uri>(eventUrl + bundleName_tokeId);
    m_calendarUri = std::make_unique<Uri>(calendarUrl + bundleName_tokeId);
}

Calendar::Calendar(CalendarAccount account, int id)
    :m_account(std::move(account)), m_id(id)
{
    // todo getallcalendar的时候会重复，需要复用
    uint64_t tokenId = CalendarEnv::GetInstance().GetTokenId();
    auto bumdleName = CalendarEnv::GetInstance().GetBundleName();
    auto bundleName_tokeId = "?bundleName=" + bumdleName + "&tokenId=" + std::to_string(tokenId);
    LOG_INFO("bundleName_tokeId: %{public}s", bundleName_tokeId.c_str());
    m_eventUri = std::make_unique<Uri>(eventUrl + bundleName_tokeId);
    m_attendeeUri = std::make_unique<Uri>(attendeeUrl + bundleName_tokeId);
    m_calendarUri = std::make_unique<Uri>(calendarUrl + bundleName_tokeId);
    m_reminderUrl = std::make_unique<Uri>(reminderUrl + bundleName_tokeId);
}
void Calendar::InsertReminders(int eventId, vector<int> reminders)
{
    for (const auto &reminder : reminders) {
            DataShare::DataShareValuesBucket valuesBucket;
            valuesBucket.Put("event_id", eventId);
            valuesBucket.Put("minutes", reminder);
            auto index = DataShareHelperManager::GetInstance().Insert(*(m_reminderUrl.get()), valuesBucket);
            LOG_INFO("Insert reminder index %{public}d", index);
        }
}

int Calendar::AddEvent(const Event& event)
{
    auto valueEvent = BuildValueEvent(event, m_id);
    auto eventId = DataShareHelperManager::GetInstance().Insert(*(m_eventUri.get()), valueEvent);
    LOG_INFO("Insert Event eventId %{public}d", eventId);
    if (eventId <= 0) {
        return eventId;
    }
    // insert attendee
    auto valueAttendees = std::vector<DataShare::DataShareValuesBucket>();
    for (const auto &attendee : event.attendees) {
        auto valueAttendee = BuildAttendeeValue(attendee, eventId);
        valueAttendees.emplace_back(valueAttendee);
    }
    if (valueAttendees.size() > 0) {
        auto count = DataShareHelperManager::GetInstance().BatchInsert(*(m_attendeeUri.get()), valueAttendees);
        LOG_INFO("batchInsert attendees count %{public}d", count);
    }
    
    // insert reminder
    if (event.reminderTime.has_value()) {
        InsertReminders(eventId, event.reminderTime.value());
    }

    return eventId;
}
#define SUPPORT_BATCH_INSERT 0

#if SUPPORT_BATCH_INSERT
int Calendar::AddEvents(const std::vector<Event>& events)
{
    std::vector<DataShare::DataShareValuesBucket> valueEvents;
    for (const auto &event : events) {
        valueEvents.emplace_back(BuildValueEvent(event));
    }
    auto count = DataShareHelperManager::GetInstance().BatchInsert(*(m_eventUri.get()), valueEvents);
    LOG_INFO("BatchInsert count %{public}d", count);
    return count;
}
#else
int Calendar::AddEvents(const std::vector<Event>& events)
{
    int count = 0;
    for (const auto &event : events) {
        auto index = Calendar::AddEvent(event);
        if (index > 0) {
            count++;
        }
    }
    LOG_INFO("AddEvents count %{public}d", count);
    return count;
}
#endif


bool Calendar::DeleteEvent(int id)
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", id);
    predicates.EqualTo("calendar_id", GetId());
    auto ret = DataShareHelperManager::GetInstance().Delete(*(m_eventUri.get()), predicates);
    LOG_INFO("DeleteEvent number %{public}d", ret);
    {
        // delete attendee
        DataShare::DataSharePredicates predicates;
        predicates.EqualTo("event_id", id);
        auto ret = DataShareHelperManager::GetInstance().Delete(*(m_attendeeUri.get()), predicates);
        LOG_INFO("Delete attendee num %{public}d", ret);
    }
    {
        // delete reminder
        DataShare::DataSharePredicates predicates;
        predicates.EqualTo("event_id", id);
        auto ret = DataShareHelperManager::GetInstance().Delete(*(m_reminderUrl.get()), predicates);
        LOG_INFO("Delete reminder num %{public}d", ret);
    }
    return ret == 1;
}

void Calendar::DeleteAllEvents()
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", GetId());
    auto ret = DataShareHelperManager::GetInstance().Delete(*(m_eventUri.get()), predicates);
    LOG_INFO("DeleteEvent number %{public}d", ret);
    return;
}

int Calendar::DeleteEvents(const std::vector<int>& ids)
{
    int count = 0;
    for (const auto &id : ids) {
        if (DeleteEvent(id)) {
            count +=1;
        }
    }
    LOG_INFO("DeleteEvents %{public}d", count);
    return count;
}

bool Calendar::UpdateEvent(const Event& event)
{
    if (!event.id) {
        LOG_ERROR("event id not exist");
        return false;
    }
    const auto eventId = event.id.value();
    DataShare::DataSharePredicates m_predicates;
    m_predicates.EqualTo("_id", eventId);
    auto valueEvent = BuildValueEvent(event, m_id);
    auto ret = DataShareHelperManager::GetInstance().Update(*(m_eventUri.get()), m_predicates, valueEvent);
    LOG_INFO(" Update code %{public}d", ret);
    {
        // delete attendee
        DataShare::DataSharePredicates predicates;
        predicates.EqualTo("event_id", eventId);
        auto ret = DataShareHelperManager::GetInstance().Delete(*(m_attendeeUri.get()), predicates);
        LOG_INFO("Delete attendee num %{public}d", ret);
    }
    auto valueAttendees = std::vector<DataShare::DataShareValuesBucket>();
    for (const auto &attendee : event.attendees) {
        auto valueAttendee = BuildAttendeeValue(attendee, eventId);
        valueAttendees.emplace_back(valueAttendee);
    }
    if (valueAttendees.size() > 0) {
        auto count = DataShareHelperManager::GetInstance().BatchInsert(*(m_attendeeUri.get()), valueAttendees);
        LOG_INFO("batchInsert attendees count %{public}d", count);
    }
    
    {
        // delete reminder
        DataShare::DataSharePredicates predicates;
        predicates.EqualTo("event_id", eventId);
        auto ret = DataShareHelperManager::GetInstance().Delete(*(m_reminderUrl.get()), predicates);
        LOG_INFO("Delete reminder num %{public}d", ret);
    }
    if (event.reminderTime.has_value()) {
        InsertReminders(eventId, event.reminderTime.value());
    }

    return ret == 1;
}

int Calendar::UpdateEvents(const std::vector<Event>& events)
{
    int count = 0;
    for (const auto &event : events) {
        if (UpdateEvent(event)) {
            count +=1;
        }
    }
    LOG_INFO("UpdateEvents %{public}d", count);
    return count;
}

std::vector<Attendee> Calendar::GetAttendeesByEventId(int id)
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("event_id", id);
    std::vector<std::string> columns = {"attendeeName", "attendeeEmail", "attendeeRelationship"};
    DataShare::DatashareBusinessError error;
    auto result = DataShareHelperManager::GetInstance().Query(*(m_attendeeUri.get()), predicates, columns, &error);
    std::vector<Attendee> attendees;
    ResultSetToAttendees(attendees, result);
    LOG_INFO(" query attendee finished");
    return attendees;
}

std::optional<std::vector<int>> Calendar::GetRemindersByEventId(int id)
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("event_id", id);
    std::vector<std::string> columns = {"event_id", "minutes"};
    DataShare::DatashareBusinessError error;
    auto result = DataShareHelperManager::GetInstance().Query(*(m_reminderUrl.get()), predicates, columns, &error);
    std::vector<int> reminders;
    auto ret = ResultSetToReminders(reminders, result);
    if (ret != DataShare::E_OK) {
        return std::nullopt;
    }
    LOG_INFO("query reminder finished");
    return reminders;
}

std::vector<Event> Calendar::GetEvents(std::shared_ptr<EventFilter> filter, const std::vector<string>& eventKey)
{
    std::vector<Event> events;
    std::shared_ptr<DataShare::DataSharePredicates> predicates = nullptr;
    if (filter) {
        predicates = filter->GetFilterPrediacates();
        if (!predicates) {
            LOG_ERROR("predicates null");
            return events;
        }
    } else {
        predicates = std::make_shared<DataShare::DataSharePredicates>();
    }
    predicates->EqualTo("calendar_id", GetId());
    std::vector<string> queryField = {};
    std::set<string> resultSetField;
    if (eventKey.size() > 0) {
        queryField.emplace_back("_id");
        setField(eventKey, queryField, resultSetField);
    } else {
        resultSetField = {"type", "title", "startTime", "endTime", "isAllDay", "description",
        "timeZone", "location", "service", "attendee", "reminderTime"};
    }
    DataShare::DatashareBusinessError error;
    auto result = DataShareHelperManager::GetInstance().Query(*(m_eventUri.get()),
        *(predicates.get()), queryField, &error);
    if (!result) {
        LOG_ERROR("query failed");
        return events;
    }
    ResultSetToEvents(events, result, resultSetField);
    for (auto &event : events) {
        const auto eventId = event.id.value();
        if (resultSetField.count("attendee")) {
            event.attendees = GetAttendeesByEventId(eventId);
        }
        if (resultSetField.count("reminderTime")) {
            event.reminderTime = GetRemindersByEventId(eventId);
        }
        DumpEvent(event);
    }
    LOG_INFO("query finished");
    return events;
}

CalendarConfig Calendar::GetConfig()
{
    return m_config;
}

bool Calendar::SetConfig(const CalendarConfig& config)
{
    DataShare::DataSharePredicates m_predicates;
    m_predicates.EqualTo("_id", m_id);
    DataShare::DataShareValuesBucket valuesBucket;
    if (std::get_if<1>(&config.color)) {
        valuesBucket.Put("calendar_color", std::get<1>(config.color));
    }
    if (config.enableReminder) {
        valuesBucket.Put("canReminder", config.enableReminder.value());
    }
    if (valuesBucket.IsEmpty()) {
        LOG_INFO("no need update");
        return true;
    }

    // dataShareHelper 需要提到event_handler基类里面去
    auto ret = DataShareHelperManager::GetInstance().Update(*(m_calendarUri.get()), m_predicates, valuesBucket) == 1;
    LOG_INFO("SetConfig %{public}d", ret);
    if (ret) {
        m_config = config;
    }
    return ret;
}
}