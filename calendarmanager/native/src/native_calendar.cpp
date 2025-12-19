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
#include "calendar_env.h"
#include "data_ability_helper.h"
#include "native_util.h"
#include "napi_queue.h"

namespace {
    const string eventUrl = "datashare:///calendardata/Events";
    const string attendeeUrl = "datashare:///calendardata/Attendees";
    const string calendarUrl = "datashare:///calendardata/Calendars";
    const string reminderUrl = "datashare:///calendardata/Reminders";
    const string instanceUrl = "datashare:///calendardata/Instances";
}
namespace OHOS::CalendarApi::Native {
Calendar::Calendar(int id)
    : m_id(id)
{
    uint64_t tokenId = CalendarEnv::GetInstance().GetTokenId();
    auto bumdleName = CalendarEnv::GetInstance().GetBundleName();
    auto bundleName_tokeId = "?bundleName=" + bumdleName + "&tokenId=" + std::to_string(tokenId);
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
    m_eventUri = std::make_unique<Uri>(eventUrl + bundleName_tokeId);
    m_attendeeUri = std::make_unique<Uri>(attendeeUrl + bundleName_tokeId);
    m_calendarUri = std::make_unique<Uri>(calendarUrl + bundleName_tokeId);
    m_reminderUrl = std::make_unique<Uri>(reminderUrl + bundleName_tokeId);
    m_instanceUrl = std::make_unique<Uri>(instanceUrl + bundleName_tokeId);
}
void Calendar::InsertReminders(int eventId, vector<int> reminders)
{
    std::sort(reminders.begin(), reminders.end());
    reminders.erase(std::unique(reminders.begin(), reminders.end()), reminders.end());
    for (const auto &reminder : reminders) {
            DataShare::DataShareValuesBucket valuesBucket;
            valuesBucket.Put("event_id", eventId);
            valuesBucket.Put("minutes", reminder);
            auto insertRet = DataShareHelperManager::GetInstance().Insert(*(m_reminderUrl.get()), valuesBucket);
            if (insertRet.is_ok()) {
                LOG_INFO("Insert reminder index %{private}d", insertRet.value());
            } else {
                LOG_ERROR("insert reminder error %{public}d", insertRet.error().code);
            }
        }
}

Result<int> Calendar::AddEventInfo(const Event& event, int channelId)
{
    const auto valueEvent = BuildValueEvent(event, m_id, channelId, false);
    auto result = DataShareHelperManager::GetInstance().Insert(*(m_eventUri.get()), valueEvent);
    if (result.is_err()) {
        LOG_ERROR("AddEventInfo insert error");
        return Result<int>(result.error());
    }
    if (result.value() <= 0) {
        LOG_ERROR("eventId error");
        return Result<int>(result.value());
    }
    auto eventId = result.value();
    LOG_INFO("Insert Event eventId %{private}d", eventId);
    // insert attendee
    auto valueAttendees = std::vector<DataShare::DataShareValuesBucket>();
    for (const auto &attendee : event.attendees) {
        auto valueAttendee = BuildAttendeeValue(attendee, eventId);
        valueAttendees.emplace_back(valueAttendee);
    }
    if (valueAttendees.size() > 0) {
        auto batchRet = DataShareHelperManager::GetInstance().BatchInsert(*(m_attendeeUri.get()), valueAttendees);
        if (batchRet.is_err()) {
            LOG_ERROR("insert attendees error, code: %{public}d", batchRet.error().code);
        } else {
            LOG_INFO("batchInsert attendees count %{private}d", batchRet.value());
        }
    }
    
    // insert reminder
    if (event.reminderTime.has_value()) {
        InsertReminders(eventId, event.reminderTime.value());
    }

    return Result<int> (eventId);
}

Result<int> Calendar::AddEvent(const Event& event)
{
    return Calendar::AddEventInfo(event, 0);
}
#define SUPPORT_BATCH_INSERT 0

#if SUPPORT_BATCH_INSERT
Result<int> Calendar::AddEvents(const std::vector<Event>& events)
{
    std::vector<DataShare::DataShareValuesBucket> valueEvents;
    for (const auto &event : events) {
        valueEvents.emplace_back(BuildValueEvent(event));
    }
    auto result = DataShareHelperManager::GetInstance().BatchInsert(*(m_eventUri.get()), valueEvents);
    if (result.is_ok()) {
        LOG_INFO("BatchInsert count %{private}d", result.value());
    } else {
        return Result<int>(result.error());
    }
    return Result<int>(result.value());
}
#else
Result<int> Calendar::AddEvents(const std::vector<Event>& events)
{
    int count = 0;
    int channelId = 0;
    Error error = {"", 0};
    for (const auto &event : events) {
        auto result = Calendar::AddEventInfo(event, channelId);
        if (result.is_ok()) {
            count++;
        } else {
            error = result.error();
        }
        channelId++;
    }
    LOG_INFO("AddEvents count %{private}d", count);
    if (error.code != 0) {
        return Result<int>(error);
    }
    return Result<int>(count);
}
#endif


Result<bool> Calendar::DeleteEvent(int id)
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", id);
    predicates.EqualTo("calendar_id", GetId());
    auto ret = DataShareHelperManager::GetInstance().Delete(*(m_eventUri.get()), predicates);
    if (ret.is_ok()) {
        if (ret.value() == 0) {
            LOG_ERROR("The deleted event does not exist!");
        }
        return Result<bool>(ret.value() == 1);
    } else {
        return Result<bool>(ret.error());
    }
}

void Calendar::DeleteAllEvents()
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", GetId());
    auto ret = DataShareHelperManager::GetInstance().Delete(*(m_eventUri.get()), predicates);
    return;
}

Result<int> Calendar::DeleteEvents(const std::vector<int>& ids)
{
    int count = 0;
    for (const auto &id : ids) {
        auto result = DeleteEvent(id);
        if (result.is_ok()) {
            count += 1;
        } else {
            LOG_ERROR("native deleteEvent error, code: %{public}d", result.error().code);
        }
    }
    LOG_INFO("DeleteEvents %{public}d", count);
    return Result<int>(count);
}

Result<bool> Calendar::UpdateEvent(const Event& event)
{
    if (!event.id) {
        LOG_ERROR("event id not exist");
        return Result<bool>(Error{"", PARAMETER_VALUE_OUTRANGE});
    }
    const auto eventId = event.id.value();
    DataShare::DataSharePredicates m_predicates;
    m_predicates.EqualTo("_id", eventId);
    const auto valueEvent = BuildValueEvent(event, m_id, 0, true);
    auto ret = DataShareHelperManager::GetInstance().Update(*(m_eventUri.get()), m_predicates, valueEvent);
    if (ret.is_err()) {
        LOG_ERROR("Update event error");
        return Result<bool>(ret.error());
    }
    if (ret.value() == 0) {
        LOG_ERROR("The event is not exist");
        return Result<bool>(Error{"", PARAMETER_VALUE_OUTRANGE});
    }
    {
        // delete attendee
        DataShare::DataSharePredicates predicates;
        predicates.EqualTo("event_id", eventId);
        auto ret = DataShareHelperManager::GetInstance().Delete(*(m_attendeeUri.get()), predicates);
        CheckIntRetPrintLog(ret, "updateEvent delete attendee error", "Delete attendee num");
    }
    auto valueAttendees = std::vector<DataShare::DataShareValuesBucket>();
    for (const auto &attendee : event.attendees) {
        auto valueAttendee = BuildAttendeeValue(attendee, eventId);
        valueAttendees.emplace_back(valueAttendee);
    }
    if (valueAttendees.size() > 0) {
        auto count = DataShareHelperManager::GetInstance().BatchInsert(*(m_attendeeUri.get()), valueAttendees);
        CheckIntRetPrintLog(count, "updateEvent batchInsert attendee error", "batchInsert attendee count");
    }
    
    {
        // delete reminder
        DataShare::DataSharePredicates predicates;
        predicates.EqualTo("event_id", eventId);
        auto ret = DataShareHelperManager::GetInstance().Delete(*(m_reminderUrl.get()), predicates);
        CheckIntRetPrintLog(ret, "updateEvent delete reminder error", "Delete reminder num");
    }
    if (event.reminderTime.has_value()) {
        InsertReminders(eventId, event.reminderTime.value());
    }

    return Result<bool>(ret.value() == 1);
}

int Calendar::UpdateEvents(const std::vector<Event>& events)
{
    int count = 0;
    for (const auto &event : events) {
        auto result = UpdateEvent(event);
        if (result.is_ok()) {
            count +=1;
        }
    }
    LOG_INFO("UpdateEvents %{public}d", count);
    return count;
}

void Calendar::GetAttendeesByEventIds(const std::vector<std::string> &ids, std::vector<Event> &events)
{
    DataShare::DataSharePredicates predicates;
    predicates.In("event_id", ids);
    std::vector<std::string> columns = {"event_id", "attendeeName", "attendeeEmail",
    "attendeeRelationship", "attendeeStatus", "attendeeType"};
    DataShare::DatashareBusinessError dataShareError;
    auto result = DataShareHelperManager::GetInstance()
        .Query(*(m_attendeeUri.get()), predicates, columns);
    if (result.is_err()) {
        LOG_ERROR("GetAttendees error, errCode: %{public}d", result.error().code);
        return;
    }
    auto attendeesResult = result.value();
    if (attendeesResult == nullptr) {
        LOG_INFO("attendees result is null");
        return;
    }
    auto ret = ResultSetToMultiAttendees(events, attendeesResult);
    attendeesResult->Close();
    if (ret != DataShare::E_OK) {
        LOG_ERROR("result set to attendees failed");
        return;
    }
    LOG_INFO(" query attendee finished");
}

void Calendar::GetRemindersByEventIds(const std::vector<std::string> &ids, std::vector<Event> &events)
{
    DataShare::DataSharePredicates predicates;
    predicates.In("event_id", ids);
    std::vector<std::string> columns = {"event_id", "minutes"};
    auto result = DataShareHelperManager::GetInstance()
        .Query(*(m_reminderUrl.get()), predicates, columns);
    if (result.is_err()) {
        LOG_ERROR("GetReminder error, errCode: %{public}d", result.error().code);
        return;
    }
    auto reminderResult = result.value();
    if (reminderResult == nullptr) {
        LOG_ERROR("reminders result is null");
        return;
    }
    auto ret = ResultSetToMultiReminders(events, reminderResult);
    reminderResult->Close();
    if (ret != DataShare::E_OK) {
        LOG_ERROR("result set to reminders failed");
        return;
    }
    LOG_INFO("query reminder finished");
}

Result<std::vector<Event>> Calendar::GetEvents
    (std::shared_ptr<EventFilter> filter, const std::vector<string>& eventKey)
{
    std::vector<Event> events;
    std::shared_ptr<DataShare::DataSharePredicates> predicates = nullptr;
    if (filter) {
        predicates = filter->GetFilterPrediacates();
        if (!predicates) {
            LOG_ERROR("predicates null");
            return Result<std::vector<Event>>(events);
        }
    } else {
        predicates = std::make_shared<DataShare::DataSharePredicates>();
    }
    predicates->EqualTo("calendar_id", GetId());
    std::vector<string> queryField = {};
    std::set<string> resultSetField;
    Error error = {"", 0};
    if (eventKey.size() > 0) {
        queryField.emplace_back("_id");
        SetField(eventKey, queryField, resultSetField, error);
        CHECK_ERRCODE_RETURN(error, "getEvents eventKeys error", Result<std::vector<Event>>(error));
    } else {
        resultSetField = {"type", "title", "startTime", "endTime", "isAllDay", "description",
        "timeZone", "location", "service", "attendee", "reminderTime", "identifier"};
    }
    auto result = DataShareHelperManager::GetInstance().Query(*(m_eventUri.get()),
        *(predicates.get()), queryField);
    if (result.is_err()) {
        LOG_ERROR("query failed %{public}d, %{public}s", result.error().code, result.error().message.c_str());
        return Result<std::vector<Event>>(result.error());
    }
    auto queryRet = result.value();
    std::vector<std::string> eventIds;
    ResultSetToEvents(eventIds, events, queryRet, resultSetField);
    queryRet->Close();
    size_t segmentSize = 10000;
    for (size_t i = 0; i < eventIds.size(); i += segmentSize) {
        size_t start = i;
        size_t end = std::min(i + segmentSize, eventIds.size());
        std::vector<std::string> queryIdsVec;
        for (size_t j = start; j < end; ++j) {
            queryIdsVec.emplace_back(eventIds[j]);
        }
        FillEventsInfo(queryIdsVec, events, resultSetField);
    }
    LOG_INFO("query finished");
    return Result<std::vector<Event>>(events);
}

void Calendar::FillEventsInfo(const std::vector<std::string> &eventIds, std::vector<Event> &events,
    const std::set<std::string>& resultSetField)
{
    if (resultSetField.count("attendee")) {
        GetAttendeesByEventIds(eventIds, events);
    }
    if (resultSetField.count("reminderTime")) {
        GetRemindersByEventIds(eventIds, events);
    }
}

Result<std::vector<Event>> Calendar::QueryEventInstances(int64_t start,
    int64_t end, const std::vector<int> &ids, const std::vector<string>& eventKey)
{
    LOG_INFO("query instance start");
    std::vector<Event> events;
    std::shared_ptr<DataShare::DataSharePredicates> predicates = std::make_shared<DataShare::DataSharePredicates>();
    predicates->EqualTo("calendar_id", GetId());
    std::vector<string> queryField = {};
    std::set<string> resultSetField;
    Error error = {"", 0};
    if (eventKey.size() > 0) {
        queryField.emplace_back("Events._id");
        SetField(eventKey, queryField, resultSetField, error);
        CHECK_ERRCODE_RETURN(error, "eventKeys error", Result<std::vector<Event>>(error));
    } else {
        resultSetField = {"id", "title", "startTime", "endTime", "instanceStartTime", "instanceEndTime",
        "isAllDay", "description", "timeZone", "location", "service"};
        queryField = {"Events._id", "title", "dtstart", "dtend", "service_type", "service_cp_bz_uri",
        "service_description", "allDay", "eventTimezone", "description", "eventLocation",
         "location_longitude", "location_latitude", "begin", "end"};
    }
    auto url = "&begin=" + std::to_string(start) + "&end=" + std::to_string(end) +
         "&calendarId=" + std::to_string(GetId()) +"&orderByAsc=startDay";
    std::string idsString = EventIdsToString(ids);
    if (!idsString.empty()) {
        url = url + "&eventIds=" + idsString;
    }
    m_instanceUrl = std::make_unique<Uri>(m_instanceUrl->ToString() + url);
    auto result = DataShareHelperManager::GetInstance()
        .Query(*(m_instanceUrl.get()), *(predicates.get()), queryField);
    if (result.is_err()) {
        LOG_ERROR("query failed %{public}d, %{public}s", result.error().code, result.error().message.c_str());
        return Result<std::vector<Event>>(result.error());
    }
    auto queryRet = result.value();
    std::vector<std::string> eventIds;
    ResultSetToEvents(eventIds, events, queryRet, resultSetField);
    queryRet->Close();
    FillEventsInfo(eventIds, events, resultSetField);
    LOG_INFO("query instance finished");
    return Result<std::vector<Event>>(events);
}

CalendarConfig Calendar::GetConfig()
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", m_id);
    std::vector<std::string> columns = {"calendar_color", "canReminder"};
    auto result = DataShareHelperManager::GetInstance().Query(*(m_calendarUri.get()), predicates, columns);
    if (result.is_err()) {
        LOG_ERROR("get config error");
    } else {
        auto queryRet = result.value();
        ResultSetToConfig(m_config, queryRet);
    }
    LOG_INFO(" query config finished");
    return m_config;
}

Result<bool> Calendar::SetConfig(const CalendarConfig& config)
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
        return Result<bool>(true);
    }

    auto ret = DataShareHelperManager::GetInstance()
    .Update(*(m_calendarUri.get()), m_predicates, valuesBucket);
    if (ret.is_err()) {
        LOG_ERROR("native setConfig error, code: %{public}d", ret.error().code);
        return Result<bool>(ret.error());
    } else {
        auto setRet = ret.value();
        LOG_INFO("SetConfig %{public}d", setRet);
        m_config = config;
        return Result<bool>(setRet == 1);
    }
}

}