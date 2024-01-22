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
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include <memory>
#include "native_calendar.h"
#include "calendar_log.h"
#include "native_calendar_manager.h"


namespace OHOS::CalendarApi::Native {
const std::string TEST_NAME = "EventReminderTest";
static CalendarAccount account {
    TEST_NAME,
    "local",
    "EventReminderTest"
};
class EventReminderTest : public testing::Test {
public:
    static void SetUpTestSuite(void)
    {
        calendar = CalendarManager::GetInstance().CreateCalendar(account);
        ASSERT_TRUE(calendar != nullptr);
        LOG_INFO("SetUpTestCase SUCCESS");
    }

    static void TearDownTestSuite(void)
    {
        auto ret = CalendarManager::GetInstance().DeleteCalendar(*calendar.get());
        ASSERT_TRUE(ret);
        LOG_INFO("TearDownTestSuite SUCCESS");
    }
    void SetUp() {};
    void TearDown() {};
    static std::shared_ptr<Calendar> calendar;
};

std::shared_ptr<Calendar> EventReminderTest::calendar = nullptr;

HWTEST_F(EventReminderTest, AddEventWithReminder, testing::ext::TestSize.Level1)
{
    Event event;
    const string title = "AddEventWithReminder";
    const std::vector<int> reminderTime = {0, 1, 2};
    event.title = title;
    event.reminderTime = reminderTime;
    auto eventId = calendar->AddEvent(event);
    std::vector<string> eventKey;
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterByTitle(title), eventKey);
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    EXPECT_NE(resultEvent.reminderTime, std::nullopt);
    ASSERT_THAT(resultEvent.reminderTime.value(), ::testing::ElementsAreArray(reminderTime));
}

HWTEST_F(EventReminderTest, DelEventWithReminder, testing::ext::TestSize.Level1)
{
    Event event;
    const string title = "DelEventWithReminder";
    const std::vector<int> reminderTime = {0, 1, 2};
    event.title = title;
    event.reminderTime = reminderTime;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    std::vector<string> eventKey;
    auto events = calendar->GetEvents(FilterByTitle(title), eventKey);
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    EXPECT_NE(resultEvent.reminderTime, std::nullopt);
    ASSERT_THAT(resultEvent.reminderTime.value(), ::testing::ElementsAreArray(reminderTime));
    auto ret = calendar->DeleteEvent(eventId);
    ASSERT_EQ(ret, 1);
    auto reminders = calendar->GetRemindersByEventId(eventId);
    ASSERT_EQ(reminders, std::nullopt);
}

HWTEST_F(EventReminderTest, UpdateEventWithReminder, testing::ext::TestSize.Level1)
{
    Event event;
    const string title = "UpdateEventWithReminder";
    const std::vector<int> reminderTime = {0, 1, 2};
    event.title = title;
    event.reminderTime = reminderTime;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    std::vector<string> eventKey;
    auto events = calendar->GetEvents(FilterByTitle(title), eventKey);
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    EXPECT_NE(resultEvent.reminderTime, std::nullopt);
    ASSERT_THAT(resultEvent.reminderTime.value(), ::testing::ElementsAreArray(reminderTime));
    const std::vector<int> newReminderTime = {4, 5, 6};
    resultEvent.reminderTime = newReminderTime;
    auto ret = calendar->UpdateEvent(resultEvent);
    ASSERT_EQ(ret, 1);
    events = calendar->GetEvents(FilterByTitle(title), eventKey);
    ASSERT_EQ(events.size(), 1);
    auto newResultEvent = events.at(0);
    EXPECT_NE(newResultEvent.reminderTime, std::nullopt);
    ASSERT_THAT(newResultEvent.reminderTime.value(), ::testing::ElementsAreArray(newReminderTime));
}
}