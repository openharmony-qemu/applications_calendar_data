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
const std::string TEST_NAME = "EventAttendeeTest";
static CalendarAccount account {
    TEST_NAME,
    "local",
    "displayName_EventAttendeeTest"
};
class EventAttendeeTest : public testing::Test {
public:
    static void SetUpTestSuite(void)
    {
        LOG_INFO("CreateCalendar");
        calendar = CalendarManager::GetInstance().CreateCalendar(account);
        ASSERT_TRUE(calendar != nullptr);
        LOG_INFO("SetUpTestCase SUCCESS");
    }

    static void TearDownTestSuite(void)
    {
        LOG_INFO("DeleteCalendar");
        auto ret = CalendarManager::GetInstance().DeleteCalendar(*calendar.get());
        ASSERT_TRUE(ret);
        LOG_INFO("TearDownTestSuite SUCCESS");
    }
    void SetUp() {};
    void TearDown() {};
    static std::shared_ptr<Calendar> calendar;
};

std::shared_ptr<Calendar> EventAttendeeTest::calendar = nullptr;

void CompareAttendeeVec(const vector<Attendee> &v1, const vector<Attendee> &v2)
{
    ASSERT_EQ(v1.size(), v2.size());
    for (size_t i = 0; i < v1.size(); ++i) {
        EXPECT_EQ(v1[i].name, v2[i].name);
        EXPECT_EQ(v1[i].email, v2[i].email);
    }
}

HWTEST_F(EventAttendeeTest, AddEventWithOneAttendee, testing::ext::TestSize.Level1)
{
    Event event;
    string title = "AddEventWithOneAttendee";
    event.title = title;
    vector<Attendee> testAttendees {
        {"test_attendee_name", "test_attendee@abc.com", ORGANIZER},
        {"test_attendee_name1", "test_attendee1@abc.com", PARTICIPANT},
        {"test_attendee_name2", "test_attendee2@abc.com",  PARTICIPANT}
    };
    event.attendees = testAttendees;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterByTitle("AddEventWithOneAttendee"), {});
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    EXPECT_EQ(resultEvent.title.value(), title);
    CompareAttendeeVec(resultEvent.attendees, testAttendees);
}

HWTEST_F(EventAttendeeTest, DelEventWithAttendee, testing::ext::TestSize.Level1)
{
    Event event1;
    string title1 = "DelEventWithAttendee1";
    event1.title = title1;
    Event event2;
    string title2 = "DelEventWithAttendee2";
    event2.title = title2;
    vector<Attendee> testAttendees {
        {"test_attendee_name", "test_attendee@abc.com", ORGANIZER},
        {"test_attendee_name1", "test_attendee1@abc.com", PARTICIPANT},
        {"test_attendee_name2", "test_attendee2@abc.com",  PARTICIPANT}
    };
    event1.attendees = testAttendees;
    event2.attendees = testAttendees;
    auto eventId1 = calendar->AddEvent(event1);
    ASSERT_NE(eventId1, 0);
    auto eventId2 = calendar->AddEvent(event2);
    ASSERT_NE(eventId2, 0);
    auto ret = calendar->DeleteEvent(eventId1);
    ASSERT_EQ(ret, 1);
    auto events = calendar->GetEvents(FilterById({eventId2}), {});
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    ASSERT_EQ(resultEvent.title.value(), title2);
    CompareAttendeeVec(resultEvent.attendees, testAttendees);
}

HWTEST_F(EventAttendeeTest, UpdateEventWithAttendee, testing::ext::TestSize.Level1)
{
    Event event;
    vector<Attendee> testAttendees {
        {"test_attendee_name", "test_attendee@abc.com", ORGANIZER},
        {"test_attendee_name1", "test_attendee1@abc.com", PARTICIPANT},
        {"test_attendee_name2", "test_attendee2@abc.com",  PARTICIPANT}
    };
    event.attendees = testAttendees;
    auto eventId = calendar->AddEvent(event);
    ASSERT_NE(eventId, 0);
    auto events = calendar->GetEvents(FilterById({eventId}), {});
    ASSERT_EQ(events.size(), 1);
    auto resultEvent = events.at(0);
    ASSERT_THAT(resultEvent.attendees, testing::ElementsAreArray(testAttendees));
    vector<Attendee> newTestAttendees {
        {"test_attendee_name_new", "test_attendee@abc.com", ORGANIZER},
        {"test_attendee_name_new1", "test_attendee1@abc.com", PARTICIPANT},
        {"test_attendee_name_new2", "test_attendee2@abc.com", PARTICIPANT}
    };
    resultEvent.attendees = newTestAttendees;
    calendar->UpdateEvent(resultEvent);
    events = calendar->GetEvents(FilterById({eventId}), {});
    ASSERT_EQ(events.size(), 1);
    resultEvent = events.at(0);
    CompareAttendeeVec(resultEvent.attendees, newTestAttendees);
}

}