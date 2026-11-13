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
#include <regex>
#include <cmath>

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
            if (insertRet.IsOk()) {
                LOG_INFO("Insert reminder index %{private}d", insertRet.GetValue());
            } else {
                LOG_ERROR("insert reminder error %{public}d", insertRet.GetError().code);
            }
        }
}

Result<int> Calendar::AddEventInfo(const Event& event, int channelId)
{
    const auto valueEvent = BuildValueEvent(event, m_id, channelId, false);
    auto result = DataShareHelperManager::GetInstance().Insert(*(m_eventUri.get()), valueEvent);
    if (result.IsErr()) {
        LOG_ERROR("AddEventInfo insert error");
        return Result<int>(result.GetError());
    }
    if (result.GetValue() <= 0) {
        LOG_ERROR("eventId error");
        return Result<int>(result.GetValue());
    }
    auto eventId = result.GetValue();
    LOG_INFO("Insert Event eventId %{private}d", eventId);
    // insert attendee
    auto valueAttendees = std::vector<DataShare::DataShareValuesBucket>();
    for (const auto &attendee : event.attendees) {
        auto valueAttendee = BuildAttendeeValue(attendee, eventId);
        valueAttendees.emplace_back(valueAttendee);
    }
    if (valueAttendees.size() > 0) {
        auto batchRet = DataShareHelperManager::GetInstance().BatchInsert(*(m_attendeeUri.get()), valueAttendees);
        if (batchRet.IsErr()) {
            LOG_ERROR("insert attendees error, code: %{public}d", batchRet.GetError().code);
        } else {
            LOG_INFO("batchInsert attendees count %{private}d", batchRet.GetValue());
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
    if (result.IsOk()) {
        LOG_INFO("BatchInsert count %{private}d", result.GetValue());
    } else {
        return Result<int>(result.GetError());
    }
    return Result<int>(result.GetValue());
}
#else
Result<int> Calendar::AddEvents(const std::vector<Event>& events)
{
    int count = 0;
    int channelId = 0;
    Error error = {"", NO_ERROR};
    for (const auto &event : events) {
        auto result = Calendar::AddEventInfo(event, channelId);
        if (result.IsOk()) {
            count++;
        } else {
            error = result.GetError();
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
    if (ret.IsOk()) {
        if (ret.GetValue() == 0) {
            LOG_ERROR("The deleted event does not exist!");
        }
        return Result<bool>(ret.GetValue() == 1);
    } else {
        return Result<bool>(ret.GetError());
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
        if (result.IsOk()) {
            count += 1;
        } else {
            LOG_ERROR("native deleteEvent error, code: %{public}d", result.GetError().code);
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
    if (ret.IsErr()) {
        LOG_ERROR("Update event error");
        return Result<bool>(ret.GetError());
    }
    if (ret.GetValue() == 0) {
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

    return Result<bool>(ret.GetValue() == 1);
}

Result<std::string> Calendar::ReadMutationRevision(int id)
{
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", id);
    predicates.EqualTo("calendar_id", GetId());
    std::vector<std::string> columns = {"calendarMutationRevision"};
    auto result = DataShareHelperManager::GetInstance().Query(*m_eventUri, predicates, columns);
    if (result.IsErr()) { return Result<std::string>(result.GetError()); }
    auto rows = result.GetValue();
    if (rows == nullptr) { return Result<std::string>(Error{"Missing Calendar revision result", INTERNAL_ERROR}); }
    int count = 0;
    int index = 0;
    int64_t revision = -1;
    auto status = rows->GetRowCount(count);
    if (status == DataShare::E_OK && count == 1) { status = rows->GoToFirstRow(); }
    if (status == DataShare::E_OK && count == 1) { status = rows->GetColumnIndex(columns[0], index); }
    if (status == DataShare::E_OK && count == 1) { status = rows->GetLong(index, revision); }
    rows->Close();
    if (count == 0) { return Result<std::string>(Error{"Calendar event not found", QUERY_RESULT_EMPTY}); }
    if (status != DataShare::E_OK || count != 1 || revision < 0 || revision > 9007199254740990LL) {
        return Result<std::string>(Error{"Invalid Calendar revision result", INTERNAL_ERROR});
    }
    return Result<std::string>(std::to_string(GetId()) + ":" + std::to_string(id) + ":" + std::to_string(revision));
}

Result<EventSnapshot> Calendar::GetEventSnapshot(int id)
{
    if (id <= 0) { return Result<EventSnapshot>(Error{"Invalid Calendar event ID", PARAMETER_INVALID}); }
    const std::vector<std::string> keys = {"id", "type", "title", "startTime", "endTime", "isAllDay",
        "location", "description", "reminderTime", "recurrenceRule", "attendee", "service", "identifier",
        "isLunar", "timeZone"};
    // Every Event/Attendees/Reminders write advances the persistent revision in
    // its own SQLite transaction. Equal before/after revisions prove the Event
    // plus relations were read from a stable state, including legacy writers.
    for (int attempt = 0; attempt < 3; ++attempt) {
        auto before = ReadMutationRevision(id);
        if (before.IsErr()) { return Result<EventSnapshot>(before.GetError()); }
        DataShare::DataSharePredicates exact;
        exact.EqualTo("_id", id); exact.EqualTo("calendar_id", GetId());
        std::vector<std::string> columns = {"_id"};
        std::set<std::string> fields;
        Error fieldError = {"", NO_ERROR};
        SetField(keys, columns, fields, fieldError);
        if (fieldError.code != NO_ERROR) { return Result<EventSnapshot>(fieldError); }
        auto base = DataShareHelperManager::GetInstance().Query(*m_eventUri, exact, columns);
        if (base.IsErr()) { return Result<EventSnapshot>(base.GetError()); }
        auto rows = base.GetValue();
        if (rows == nullptr) { return Result<EventSnapshot>(Error{"Missing Calendar event result", INTERNAL_ERROR}); }
        std::vector<Event> events;
        std::vector<std::string> ids;
        const auto baseStatus = ResultSetToEvents(ids, events, rows, fields);
        rows->Close();
        if (baseStatus != DataShare::E_OK || events.size() != 1 || events[0].id.value_or(-1) != id) {
            return Result<EventSnapshot>(Error{"Calendar event snapshot missing", QUERY_RESULT_EMPTY});
        }
        events[0].attendees.clear();
        events[0].reminderTime = std::vector<int>{};
        for (int relation = 0; relation < 2; ++relation) {
            DataShare::DataSharePredicates predicate;
            predicate.EqualTo("event_id", id);
            std::vector<std::string> childColumns = relation == 0
                ? std::vector<std::string>{"event_id", "attendeeName", "attendeeEmail", "attendeeRelationship",
                    "attendeeStatus", "attendeeType"}
                : std::vector<std::string>{"event_id", "minutes"};
            const auto& uri = relation == 0 ? m_attendeeUri : m_reminderUrl;
            if (uri == nullptr) { return Result<EventSnapshot>(Error{"Missing Calendar relation URI", INTERNAL_ERROR}); }
            auto child = DataShareHelperManager::GetInstance().Query(*uri, predicate, childColumns);
            if (child.IsErr()) { return Result<EventSnapshot>(child.GetError()); }
            auto childRows = child.GetValue();
            if (childRows == nullptr) {
                return Result<EventSnapshot>(Error{"Missing Calendar relation result", INTERNAL_ERROR});
            }
            int count = 0;
            auto status = childRows->GetRowCount(count);
            if (status == DataShare::E_OK && count > 0) {
                status = relation == 0 ? ResultSetToMultiAttendees(events, childRows)
                    : ResultSetToMultiReminders(events, childRows);
            }
            childRows->Close();
            if (status != DataShare::E_OK || count < 0) {
                return Result<EventSnapshot>(Error{"Invalid Calendar relation result", INTERNAL_ERROR});
            }
        }
        auto after = ReadMutationRevision(id);
        if (after.IsErr()) { return Result<EventSnapshot>(after.GetError()); }
        if (before.GetValue() != after.GetValue()) { continue; }
        return Result<EventSnapshot>(EventSnapshot{events[0], after.GetValue()});
    }
    return Result<EventSnapshot>(Error{"Calendar event changed during snapshot; retry", INTERNAL_ERROR});
}

Result<bool> Calendar::ConditionalMutation(const std::string& revision, int id, const Event* event)
{
    const std::string prefix = std::to_string(GetId()) + ":" + std::to_string(id) + ":";
    if (id <= 0 || revision.size() > 64 || revision.compare(0, prefix.size(), prefix) != 0) {
        return Result<bool>(Error{"Calendar revision belongs to another event", PARAMETER_INVALID});
    }
    const auto counter = revision.substr(prefix.size());
    if (!std::regex_match(counter, std::regex("0|[1-9][0-9]{0,15}"))) {
        return Result<bool>(Error{"Invalid Calendar revision", PARAMETER_INVALID});
    }
    int64_t parsed = 0;
    for (const char digit : counter) { parsed = parsed * 10 + (digit - '0'); }
    if (parsed > 9007199254740990LL) {
        return Result<bool>(Error{"Calendar revision out of range", PARAMETER_INVALID});
    }
    DataShare::DataShareValuesBucket values;
    values.Put("__calendarMutationKind", std::string(event == nullptr ? "delete" : "update"));
    values.Put("__calendarMutationId", id);
    values.Put("__calendarMutationExpectedRevision", counter);
    if (event != nullptr) {
        if (event->type != Normal || !event->title.has_value() || event->title->empty() || event->title->size() > 20000 ||
            !event->description.has_value() || event->description->size() > 20000 ||
            event->startTime < 0 || event->endTime <= event->startTime || event->endTime > 8640000000000000LL ||
            !event->reminderTime.has_value() || event->reminderTime->size() > 1) {
            return Result<bool>(Error{"Invalid conditional Calendar edit fields", PARAMETER_INVALID});
        }
        std::string reminders;
        if (!event->reminderTime->empty()) {
            const int minutes = event->reminderTime->front();
            if (minutes < 0 || minutes > 10080) {
                return Result<bool>(Error{"Invalid Calendar reminder minutes", PARAMETER_INVALID});
            }
            reminders = std::to_string(minutes);
        }
        values.Put("title", *event->title);
        values.Put("description", *event->description);
        values.Put("dtstart", event->startTime);
        values.Put("dtend", event->endTime);
        values.Put("__calendarMutationReminders", reminders);
    }
    DataShare::DataSharePredicates predicates;
    predicates.EqualTo("_id", id);
    predicates.EqualTo("calendar_id", GetId());
    predicates.EqualTo("calendarMutationRevision", parsed);
    auto result = DataShareHelperManager::GetInstance().Update(*m_eventUri, predicates, values);
    if (result.IsErr()) { return Result<bool>(result.GetError()); }
    if (result.GetValue() != 0 && result.GetValue() != 1) {
        return Result<bool>(Error{"Unexpected conditional Calendar mutation count", INTERNAL_ERROR});
    }
    return Result<bool>(result.GetValue() == 1);
}

Result<bool> Calendar::UpdateEventIfUnchanged(const std::string& revision, const Event& event)
{
    return ConditionalMutation(revision, event.id.value_or(-1), &event);
}

Result<bool> Calendar::DeleteEventIfUnchanged(const std::string& revision, int id)
{
    return ConditionalMutation(revision, id, nullptr);
}

int Calendar::UpdateEvents(const std::vector<Event>& events)
{
    int count = 0;
    for (const auto &event : events) {
        auto result = UpdateEvent(event);
        if (result.IsOk()) {
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
    if (result.IsErr()) {
        LOG_ERROR("GetAttendees error, errCode: %{public}d", result.GetError().code);
        return;
    }
    auto attendeesResult = result.GetValue();
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
    if (result.IsErr()) {
        LOG_ERROR("GetReminder error, errCode: %{public}d", result.GetError().code);
        return;
    }
    auto reminderResult = result.GetValue();
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
    auto predicates = std::make_shared<DataShare::DataSharePredicates>();
    if (filter) {
        auto filterPredicates = filter->GetFilterPredicates();
        if (!filterPredicates) {
            LOG_ERROR("predicates null");
            return Result<std::vector<Event>>(events);
        }
        *predicates = *filterPredicates;
    }
    predicates->EqualTo("calendar_id", GetId());
    std::vector<string> queryField = {};
    std::set<string> resultSetField;
    Error error = {"invalid arg[1], i.e. invalid keys!", NO_ERROR};
    if (eventKey.size() > 0) {
        std::vector<string> filteredEventKey = NormalizeEventKey(eventKey, true);
        queryField.emplace_back("_id");
        SetField(filteredEventKey, queryField, resultSetField, error);
        CHECK_ERRCODE_RETURN(error, "getEvents eventKeys error", Result<std::vector<Event>>(error));
    } else {
        resultSetField = {"type", "title", "startTime", "endTime", "isAllDay", "description",
        "timeZone", "location", "service", "attendee", "reminderTime", "identifier"};
    }
    auto result = DataShareHelperManager::GetInstance().Query(*(m_eventUri.get()),
        *(predicates.get()), queryField);
    if (result.IsErr()) {
        LOG_ERROR("query failed, code: %{public}d", result.GetError().code);
        return Result<std::vector<Event>>(result.GetError());
    }
    auto queryRet = result.GetValue();
    if (!queryRet) {
        return Result<std::vector<Event>>(events);
    }
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
    std::string errMessage = "invalid arg[3], i.e. invalid keys!";
    std::shared_ptr<DataShare::DataSharePredicates> predicates = std::make_shared<DataShare::DataSharePredicates>();
    predicates->EqualTo("calendar_id", GetId());
    std::vector<string> queryField = {};
    std::set<string> resultSetField;
    Error error = {"", NO_ERROR};
    if (eventKey.size() > 0) {
        std::vector<string> extendedEventKey = NormalizeEventKey(eventKey, false);
        queryField.emplace_back("Events._id");
        SetField(extendedEventKey, queryField, resultSetField, error);
        error.message = (error.code == PARAMETER_INVALID) ? errMessage : "";
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
    if (result.IsErr()) {
        LOG_ERROR("query failed %{public}d, %{public}s", result.GetError().code, result.GetError().message.c_str());
        return Result<std::vector<Event>>(result.GetError());
    }
    auto queryRet = result.GetValue();
    if (!queryRet) {
        LOG_ERROR("query failed");
        return Result<std::vector<Event>>(events);
    }
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
    if (result.IsErr()) {
        LOG_ERROR("get config error");
    } else {
        auto queryRet = result.GetValue();
        if (queryRet) {
            ResultSetToConfig(m_config, queryRet);
        }
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
    if (ret.IsErr()) {
        LOG_ERROR("native setConfig error, code: %{public}d", ret.GetError().code);
        return Result<bool>(ret.GetError());
    } else {
        auto setRet = ret.GetValue();
        LOG_INFO("SetConfig %{public}d", setRet);
        m_config = config;
        return Result<bool>(setRet == 1);
    }
}

}