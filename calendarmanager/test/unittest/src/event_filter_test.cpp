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
#include <memory>
#include "native_calendar.h"
#include "calendar_log.h"
#include "native_calendar_manager.h"


namespace OHOS::CalendarApi::Native {
const std::string TEST_NAME = "EventFilterTest";
static CalendarAccount account {
    TEST_NAME,
    "EventFilterTest",
    "displayName_EventFilterTest"
};
class EventFilterTest : public testing::Test {
public:
    /* SetUpTestCase:The preset action of the test suite is executed before the first TestCase */
    static void SetUpTestSuite(void)
    {
        calendar = CalendarManager::GetInstance().GetCalendar(account);
        if (calendar != nullptr && calendar->GetAccount().name == TEST_NAME) {
            // not the default account del it
            CalendarManager::GetInstance().DeleteCalendar(*calendar.get());
        }
        LOG_INFO("CreateCalendar");
        calendar = CalendarManager::GetInstance().CreateCalendar(account);
        ASSERT_TRUE(calendar != nullptr);
        LOG_INFO("SetUpTestCase SUCCESS");
    }

    /* TearDownTestCase:The test suite cleanup action is executed after the last TestCase */
    static void TearDownTestSuite(void)
    {
        // del calendar will del all event associated
        LOG_INFO("DeleteCalendar");
        auto ret = CalendarManager::GetInstance().DeleteCalendar(*calendar.get());
        ASSERT_TRUE(ret);
        LOG_INFO("TearDownTestSuite SUCCESS");
    }
    /* SetUp:Execute before each test case */
    void SetUp() {};

    /* TearDown:Execute after each test case */
    void TearDown() {};
    static std::shared_ptr<Calendar> calendar;
};

std::shared_ptr<Calendar> EventFilterTest::calendar = nullptr;


HWTEST_F(EventFilterTest, FilterByTitle_test_normal, testing::ext::TestSize.Level1)
{
    const string title = "FilterByTitle_test_normal";
    Event event;
    event.title = title;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterByTitle(title), {});
    ASSERT_FALSE(events.empty());
    EXPECT_EQ(events.at(0).title.value(), title);
}

HWTEST_F(EventFilterTest, FilterByTitle_test_noexist, testing::ext::TestSize.Level1)
{
    const string title = "FilterByTitle_test_noexist";
    Event event;
    event.title = title;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterByTitle(title + "event"), {});
    ASSERT_TRUE(events.empty());
}

HWTEST_F(EventFilterTest, FilterById_test_normal, testing::ext::TestSize.Level1)
{
    const string title = "FilterById_test_normal";
    Event event;
    event.title = title;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterById({eventId}), {});

    ASSERT_FALSE(events.empty());
    EXPECT_EQ(events.at(0).title.value(), title);
}

HWTEST_F(EventFilterTest, FilterById_test_empty, testing::ext::TestSize.Level1)
{
    const string title = "FilterById_test_empty";
    Event event;
    event.title = title;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterById({eventId}), {});
    ASSERT_FALSE(events.empty());
    EXPECT_EQ(events.at(0).title.value(), title);
}

HWTEST_F(EventFilterTest, FilterById_test_one_not_include, testing::ext::TestSize.Level1)
{
    const string title = "FilterById_test_one_not_include";
    Event event;
    event.title = title;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterById({eventId + 1}), {});
    ASSERT_TRUE(events.empty());
}

HWTEST_F(EventFilterTest, FilterById_test_all_include, testing::ext::TestSize.Level1)
{
    const string title = "FilterById_test_all_include_1";
    Event event;
    event.title = title;
    const string title1 = "FilterById_test_all_include_2";
    Event event1;
    event1.title = title1;
    auto eventId1 = calendar->AddEvent(event);
    auto eventId2 = calendar->AddEvent(event1);
    auto events = calendar->GetEvents(FilterById({eventId1, eventId2}), {});
    ASSERT_EQ(2, events.size());
    EXPECT_EQ(events.at(0).title.value(), title);
    EXPECT_EQ(events.at(1).title.value(), title1);
}

inline static uint64_t Now()
{
    constexpr int64_t secToMicrosec = 1000000;
    constexpr int64_t microsecToNanosec = 1000;
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (ts.tv_sec * secToMicrosec + ts.tv_nsec / microsecToNanosec);
}

HWTEST_F(EventFilterTest, FilterByTime_test_001, testing::ext::TestSize.Level1)
{
    const string title = "FilterByTime_test_001";
    Event event;
    event.title = title;
    auto timeNow = Now();
    event.startTime = timeNow;
    event.endTime = timeNow + 100000;
    auto eventId = calendar->AddEvent(event);
    ASSERT_TRUE(eventId > 0);
    auto events = calendar->GetEvents(FilterByTime(event.startTime, event.endTime), {});
    ASSERT_EQ(1, events.size());
    EXPECT_EQ(events.at(0).title.value(), title);
}

HWTEST_F(EventFilterTest, FilterByTime_test_002, testing::ext::TestSize.Level1)
{
    Event event;
    event.title = "FilterByTime_test_002";
    auto timeNow = Now();
    event.startTime = timeNow;
    const int64_t interval = 100;
    event.endTime = timeNow + interval;
    auto eventId = calendar->AddEvent(event);
    ASSERT_TRUE(eventId > 0);
    auto events = calendar->GetEvents(FilterByTime(event.startTime - interval * 2, event.startTime - interval), {});
    EXPECT_TRUE(events.empty());
    events = calendar->GetEvents(FilterByTime(event.endTime + interval, event.endTime + interval * 2), {});
    ASSERT_TRUE(events.empty());
}

HWTEST_F(EventFilterTest, FilterByTime_test_003, testing::ext::TestSize.Level1)
{
    const string title1 = "FilterByTime_test_003_1";
    auto timeNow = Now();
    Event event1;
    event1.title = title1;
    event1.startTime = timeNow;
    const int64_t interval = 100;
    event1.endTime = timeNow + interval;
    const string title2 = "FilterByTime_test_003_2";
    Event event2;
    event2.title = title2;
    event2.startTime = timeNow;
    event2.endTime = timeNow + interval * 2;

    auto count = calendar->AddEvents({event1, event2});
    ASSERT_TRUE(count == 2);
    auto events = calendar->GetEvents(FilterByTime(timeNow, event2.endTime), {});
    ASSERT_EQ(2, events.size());
    EXPECT_EQ(events.at(0).title.value(), title1);
    EXPECT_EQ(events.at(1).title.value(), title2);
}
}