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
const std::string TEST_NAME = "EventLocationTest";
static CalendarAccount account {
    TEST_NAME,
    "local",
    "displayName_EventLocationTest"
};
class EventLocationTest : public testing::Test {
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

std::shared_ptr<Calendar> EventLocationTest::calendar = nullptr;

HWTEST_F(EventLocationTest, AddEventWithLocation, testing::ext::TestSize.Level1)
{
    Event event;
    const string title = "AddEventWithLocation";
    event.title = title;
    Location testLocation {
        "test",
        123,
        456
    };
    event.location = std::make_optional<Location>(testLocation);
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterByTitle(title), {});
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    EXPECT_EQ(resultEvent.title.value(), title);
    ASSERT_NE(resultEvent.location, std::nullopt);
    auto result = resultEvent.location.value();
    EXPECT_EQ(result.location.value(), testLocation.location.value());
    EXPECT_EQ(result.longitude.value(), testLocation.longitude.value());
    EXPECT_EQ(result.latitude.value(), testLocation.latitude.value());
}
}