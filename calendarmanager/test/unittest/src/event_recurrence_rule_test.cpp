/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
#include "native_calendar_manager.h"
#include "native_util.h"


namespace OHOS::CalendarApi::Native {
const std::string TEST_NAME = "EventRecurrenceRuleTest";
static CalendarAccount account {
    TEST_NAME,
    "local",
    "displayName_EventRecurrenceRuleTest"
};
class EventRecurrenceRuleTest : public testing::Test {
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

std::shared_ptr<Calendar> EventRecurrenceRuleTest::calendar = nullptr;


HWTEST_F(EventRecurrenceRuleTest, GetUTCTime, testing::ext::TestSize.Level1)
{
    const int64_t timeValue = 1713672150000;
    const std::string timeStr = "20240421T040230Z";

    const auto timeUTCStr = GetUTCTime(timeValue);

    EXPECT_EQ(timeStr, timeUTCStr);
}

HWTEST_F(EventRecurrenceRuleTest, GetUTCTimes, testing::ext::TestSize.Level1)
{
    std::vector<int64_t> excludedDates;
    const int64_t timeValue = 1713672150000;
    const std::string timeStr = "20240421T040230Z";

    excludedDates.emplace_back(timeValue);
    const auto timeUTCStr = GetUTCTimes(excludedDates);
    EXPECT_EQ(timeStr, timeUTCStr);

    const int64_t timeVal = 1718942550000;
    excludedDates.emplace_back(timeVal);
    const std::string timeString = "20240421T040230Z,20240621T040230Z";

    const auto timeUTCString = GetUTCTimes(excludedDates);
    EXPECT_EQ(timeString, timeUTCString);
}

HWTEST_F(EventRecurrenceRuleTest, TimeToUTC, testing::ext::TestSize.Level1)
{
    const int64_t timeValue = 1713643350000;
    const std::string timeStr = "20240421T040230Z";

    const int64_t timeUTCValue = TimeToUTC(timeStr);

    EXPECT_EQ(timeValue, timeUTCValue);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithDay, testing::ext::TestSize.Level1)
{
    const int64_t timeValue = 1713672150000;
    Event event;
    event.startTime = 1713664950000;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = DAILY;
    recurrenceRule.expire = std::make_optional<int64_t>(timeValue);
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=DAILY;WKST=SU;UNTIL=20240421T040230Z";
    
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithWeekly, testing::ext::TestSize.Level1)
{
    Event event;
    event.startTime = 1713664950000;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = WEEKLY;
    recurrenceRule.interval = std::make_optional<int64_t>(2);
    recurrenceRule.count = std::make_optional<int64_t>(3);
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=WEEKLY;WKST=SU;BYDAY=SU;COUNT=3;INTERVAL=2";
    
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithMonthly, testing::ext::TestSize.Level1)
{
    const int64_t timeValue = 1713672150000;
    Event event;
    event.startTime = 1713664950000;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = MONTHLY;
    recurrenceRule.expire = std::make_optional<int64_t>(timeValue);
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=MONTHLY;WKST=SU;BYMONTHDAY=21;UNTIL=20240421T040230Z";
    
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithYearly, testing::ext::TestSize.Level1)
{
    const int64_t timeValue = 1713672150000;
    Event event;
    event.startTime = 1713664950000;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = YEARLY;
    recurrenceRule.expire = std::make_optional<int64_t>(timeValue);
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=YEARLY;WKST=SU;BYMONTHDAY=21;BYMONTH=4;UNTIL=20240421T040230Z";
    
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}
HWTEST_F(EventRecurrenceRuleTest, GetRuleWithWeeklyList, testing::ext::TestSize.Level1)
{
    Event event;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = WEEKLY;
    recurrenceRule.daysOfWeek = {1, 2, 3, 4, 5, 6, 7};
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=WEEKLY;WKST=SU;BYDAY=MO,TU,WE,TH,FR,SA,SU";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithWeeksOfMonthlyList, testing::ext::TestSize.Level1)
{
    Event event;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = MONTHLY;
    recurrenceRule.weeksOfMonth = {2, 3};
    recurrenceRule.daysOfWeek = {3, 5};
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=MONTHLY;WKST=SU;BYDAY=2WE,3FR";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithDaysOfMonthlyList, testing::ext::TestSize.Level1)
{
    Event event;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = MONTHLY;
    recurrenceRule.daysOfMonth = {18, 19};
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=MONTHLY;WKST=SU;BYMONTHDAY=18,19";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithMonthsOfYearlyList, testing::ext::TestSize.Level1)
{
    Event event;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = YEARLY;
    recurrenceRule.monthsOfYear = {5, 6};
    recurrenceRule.daysOfMonth = {20, 21};
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=YEARLY;WKST=SU;BYMONTHDAY=20,21;BYMONTH=5,6";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithDaysOfYearlyList, testing::ext::TestSize.Level1)
{
    Event event;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = YEARLY;
    recurrenceRule.daysOfYear = {180, 360, 365};
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=YEARLY;WKST=SU;BYYEARDAY=180,360,365";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithWeeksOfYearlyList, testing::ext::TestSize.Level1)
{
    Event event;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = YEARLY;
    recurrenceRule.weeksOfYear = {5, 6, 7};
    recurrenceRule.daysOfWeek = {5, 6, 7};
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=YEARLY;WKST=SU;BYWEEKNO=5,6,7;BYDAY=FR,SA,SU";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithYearlyList, testing::ext::TestSize.Level1)
{
    Event event;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = YEARLY;
    recurrenceRule.interval = 2;
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=YEARLY;INTERVAL=2;WKST=SU";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, GetRuleWithDayOfWeekMonthYearlyList, testing::ext::TestSize.Level1)
{
    Event event;
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = YEARLY;
    recurrenceRule.daysOfWeek = {1, 3, 5};
    recurrenceRule.weeksOfMonth = {2, 3, 4};
    recurrenceRule.monthsOfYear = {6, 7, 8};
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=YEARLY;BYDAY=2MO,3WE,4FR;BYMONTH=6,7,8;WKST=SU";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

}