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
const std::string TEST_NAME = "EventServiceTest";
static CalendarAccount account {
    TEST_NAME,
    "local",
    "EventServiceTest"
};
class EventServiceTest : public testing::Test {
public:
    static void SetUpTestSuite(void)
    {
        calendar = CalendarManager::GetInstance().CreateCalendar(account);
        ASSERT_TRUE(calendar != nullptr);
    }

    static void TearDownTestSuite(void)
    {
        auto ret = CalendarManager::GetInstance().DeleteCalendar(*calendar.get());
        ASSERT_TRUE(ret);
    }
    void SetUp() {};
    void TearDown() {};
    static std::shared_ptr<Calendar> calendar;
};

std::shared_ptr<Calendar> EventServiceTest::calendar = nullptr;

HWTEST_F(EventServiceTest, AddEventWithService, testing::ext::TestSize.Level1)
{
    Event event;
    const string title = "AddEventWithService";
    event.title = title;
    EventService testService {
        "Meeting",
        "//testuri",
        "test_discription"
    };
    event.service = std::make_optional<EventService>(testService);
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterByTitle(title), {});
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    EXPECT_EQ(resultEvent.title.value(), title);
    ASSERT_NE(resultEvent.service, std::nullopt);
    auto result = resultEvent.service.value();
    EXPECT_EQ(result.type, testService.type);
    EXPECT_EQ(result.uri, testService.uri);
    EXPECT_EQ(result.description.value(), testService.description.value());
}

HWTEST_F(EventServiceTest, AddEventWithNoService, testing::ext::TestSize.Level1)
{
    Event event;
    const string title = "AddEventWithNoService";
    event.title = title;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterByTitle(title), {});
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    EXPECT_EQ(resultEvent.title.value(), title);
    ASSERT_EQ(resultEvent.service, std::nullopt);
}
}