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
        auto result = CalendarManager::GetInstance().CreateCalendar(account);
        calendar = result.value();
        ASSERT_TRUE(calendar != nullptr);
    }

    static void TearDownTestSuite(void)
    {
        auto ret = CalendarManager::GetInstance().DeleteCalendar(*calendar.get());
        ASSERT_TRUE(ret.value());
    }
    void SetUp() {};
    void TearDown() {};
    static std::shared_ptr<Calendar> calendar;
};

std::shared_ptr<Calendar> EventRecurrenceRuleTest::calendar = nullptr;

HWTEST_F(EventRecurrenceRuleTest, SetRRuleValueNORule, testing::ext::TestSize.Level1)
{
    RecurrenceRule out;
    out.recurrenceFrequency = NORULE;
    RecurrenceRule newOut;
    newOut.count = 10;
    newOut.interval = 1;
    newOut.recurrenceFrequency = DAILY;
    std::string value;
    std::map<std::string, std::string> ruleMap;
    ruleMap.insert(std::pair<std::string, std::string>("FREQ", "DAILY"));
    ruleMap.insert(std::pair<std::string, std::string>("COUNT", "10"));
    ruleMap.insert(std::pair<std::string, std::string>("INTERVAL", "1"));
    SetRRuleValue(ruleMap, out);
    ASSERT_EQ(newOut.recurrenceFrequency, out.recurrenceFrequency);
    ASSERT_EQ(newOut.interval.value(), out.interval.value());
    ASSERT_EQ(newOut.count.value(), out.count.value());
}

HWTEST_F(EventRecurrenceRuleTest, SetRRuleValueByWeekDay, testing::ext::TestSize.Level1)
{
    RecurrenceRule out;
    out.recurrenceFrequency = WEEKLY;
    RecurrenceRule newOut;
    newOut.recurrenceFrequency = WEEKLY;
    newOut.daysOfWeek = std::make_optional<vector<int64_t>>();
    newOut.daysOfWeek->push_back(3);
    std::string value;
    std::map<std::string, std::string> ruleMap;
    ruleMap.insert(std::pair<std::string, std::string>("FREQ", "WEEKLY"));
    ruleMap.insert(std::pair<std::string, std::string>("BYDAY", "WE"));
    SetRRuleValue(ruleMap, out);
    ASSERT_EQ(newOut.recurrenceFrequency, out.recurrenceFrequency);
    ASSERT_EQ(newOut.daysOfWeek.value()[0], out.daysOfWeek.value()[0]);
}

HWTEST_F(EventRecurrenceRuleTest, SetRRuleValueByMonthWeekDay, testing::ext::TestSize.Level1)
{
    RecurrenceRule out;
    out.recurrenceFrequency = MONTHLY;
    RecurrenceRule newOut;
    newOut.daysOfWeek = std::make_optional<vector<int64_t>>();
    newOut.weeksOfMonth = std::make_optional<vector<int64_t>>();
    newOut.daysOfWeek->push_back(2);
    newOut.weeksOfMonth->push_back(1);
    newOut.recurrenceFrequency = MONTHLY;
    newOut.expire = 1713643350000;
    std::string value;
    std::map<std::string, std::string> ruleMap;
    ruleMap.insert(std::pair<std::string, std::string>("FREQ", "MONTHLY"));
    ruleMap.insert(std::pair<std::string, std::string>("BYDAY", "1TU"));
    ruleMap.insert(std::pair<std::string, std::string>("UNTIL", "20240421T040230Z"));
    SetRRuleValue(ruleMap, out);
    ASSERT_EQ(newOut.recurrenceFrequency, out.recurrenceFrequency);
    ASSERT_EQ(newOut.weeksOfMonth.value()[0], out.weeksOfMonth.value()[0]);
    ASSERT_EQ(newOut.daysOfWeek.value()[0], out.daysOfWeek.value()[0]);
    ASSERT_EQ(newOut.expire.value(), out.expire.value());
}

HWTEST_F(EventRecurrenceRuleTest, SetRRuleValueByYearMonthDay, testing::ext::TestSize.Level1)
{
    RecurrenceRule out;
    out.recurrenceFrequency = YEARLY;
    RecurrenceRule newOut;
    newOut.daysOfMonth = std::make_optional<vector<int64_t>>();
    newOut.monthsOfYear = std::make_optional<vector<int64_t>>();
    newOut.recurrenceFrequency = YEARLY;
    newOut.monthsOfYear->push_back(3);
    newOut.daysOfMonth->push_back(8);
    std::string value;
    std::map<std::string, std::string> ruleMap;
    ruleMap.insert(std::pair<std::string, std::string>("FREQ", "YEARLY"));
    ruleMap.insert(std::pair<std::string, std::string>("BYMONTHDAY", "8"));
    ruleMap.insert(std::pair<std::string, std::string>("BYMONTH", "3"));
    SetRRuleValue(ruleMap, out);
    ASSERT_EQ(newOut.recurrenceFrequency, out.recurrenceFrequency);
    ASSERT_EQ(newOut.monthsOfYear.value()[0], out.monthsOfYear.value()[0]);
    ASSERT_EQ(newOut.daysOfMonth.value()[0], out.daysOfMonth.value()[0]);
}

HWTEST_F(EventRecurrenceRuleTest, SetRRuleValueByYearWeekDay, testing::ext::TestSize.Level1)
{
    RecurrenceRule out;
    out.recurrenceFrequency = YEARLY;
    RecurrenceRule newOut;
    newOut.daysOfWeek = std::make_optional<vector<int64_t>>();
    newOut.weeksOfYear = std::make_optional<vector<int64_t>>();
    newOut.recurrenceFrequency = YEARLY;
    newOut.daysOfWeek->push_back(6);
    newOut.weeksOfYear->push_back(6);
    std::string value;
    std::map<std::string, std::string> ruleMap;
    ruleMap.insert(std::pair<std::string, std::string>("FREQ", "YEARLY"));
    ruleMap.insert(std::pair<std::string, std::string>("BYWEEKNO", "6"));
    ruleMap.insert(std::pair<std::string, std::string>("BYDAY", "SA"));
    SetRRuleValue(ruleMap, out);
    ASSERT_EQ(newOut.recurrenceFrequency, out.recurrenceFrequency);
    ASSERT_EQ(newOut.daysOfWeek.value()[0], out.daysOfWeek.value()[0]);
    ASSERT_EQ(newOut.weeksOfYear.value()[0], out.weeksOfYear.value()[0]);
}

HWTEST_F(EventRecurrenceRuleTest, SetRRuleValueByYearDay, testing::ext::TestSize.Level1)
{
    RecurrenceRule out;
    out.recurrenceFrequency = YEARLY;
    RecurrenceRule newOut;
    newOut.daysOfYear = std::make_optional<vector<int64_t>>();
    newOut.recurrenceFrequency = YEARLY;
    newOut.daysOfYear->push_back(36);
    std::string value;
    std::map<std::string, std::string> ruleMap;
    ruleMap.insert(std::pair<std::string, std::string>("FREQ", "YEARLY"));
    ruleMap.insert(std::pair<std::string, std::string>("BYYEARDAY", "36"));
    SetRRuleValue(ruleMap, out);
    ASSERT_EQ(newOut.recurrenceFrequency, out.recurrenceFrequency);
    ASSERT_EQ(newOut.daysOfYear.value()[0], out.daysOfYear.value()[0]);
}

HWTEST_F(EventRecurrenceRuleTest, SetByDayOfRRuleTest, testing::ext::TestSize.Level1)
{
    std::vector<std::string> weekDayList;
    weekDayList.push_back("2MO");
    RecurrenceRule out;
    RecurrenceRule newOut;
    newOut.count = 10;
    newOut.interval = 1;
    newOut.recurrenceFrequency = DAILY;
    newOut.daysOfWeek = std::make_optional<vector<int64_t>>();
    newOut.weeksOfMonth = std::make_optional<vector<int64_t>>();
    newOut.daysOfWeek->push_back(1);
    newOut.weeksOfMonth->push_back(2);
    SetByDayOfRRule(weekDayList, out);
    auto outDaysOfWeekList = out.daysOfWeek.value();
    auto newDaysOfWeekList = newOut.daysOfWeek.value();
    auto outWeeksOfMonthList = out.weeksOfMonth.value();
    auto newWeeksOfMonthList = newOut.weeksOfMonth.value();
    ASSERT_EQ(newDaysOfWeekList[0], outDaysOfWeekList[0]);
    ASSERT_EQ(newWeeksOfMonthList[0], outWeeksOfMonthList[0]);
}

HWTEST_F(EventRecurrenceRuleTest, ColorParse, testing::ext::TestSize.Level1)
{
    std::string colorStr = "123";
    variant<string, int64_t> colorValue;
    colorValue = 123;
    bool corlor = ColorParse(colorStr, colorValue);

    ASSERT_EQ(corlor, 0);
}

HWTEST_F(EventRecurrenceRuleTest, ColorParseRed, testing::ext::TestSize.Level1)
{
    std::string colorStr = "#FF0000";
    variant<string, int64_t> colorValue;
    colorValue = 123;
    bool corlor = ColorParse(colorStr, colorValue);

    ASSERT_EQ(corlor, 1);
}

HWTEST_F(EventRecurrenceRuleTest, ColorParseNULL, testing::ext::TestSize.Level1)
{
    std::string colorStr = "";
    variant<string, int64_t> colorValue;
    colorValue = 123;
    bool corlor = ColorParse(colorStr, colorValue);

    ASSERT_EQ(corlor, 0);
}

HWTEST_F(EventRecurrenceRuleTest, ColorParseLen, testing::ext::TestSize.Level1)
{
    std::string colorStr = "#FF000";
    variant<string, int64_t> colorValue;
    colorValue = 123;
    bool corlor = ColorParse(colorStr, colorValue);

    ASSERT_EQ(corlor, 0);
}

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

HWTEST_F(EventRecurrenceRuleTest, TimeToUTCError, testing::ext::TestSize.Level1)
{
    const int64_t timeValue = 0;
    const std::string timeStr = "202404";

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
    std::string rrule = "FREQ=DAILY;UNTIL=20240421T040230Z;WKST=SU";

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
    std::string rrule = "FREQ=WEEKLY;COUNT=3;INTERVAL=2;WKST=SU;BYDAY=SU";

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
    std::string rrule = "FREQ=MONTHLY;UNTIL=20240421T040230Z;WKST=SU;BYMONTHDAY=21";

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
    std::string rrule = "FREQ=YEARLY;UNTIL=20240421T040230Z;WKST=SU;BYMONTHDAY=21;BYMONTH=4";

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
    std::string rrule = "FREQ=YEARLY;INTERVAL=2;WKST=SU;BYMONTHDAY=1;BYMONTH=1";
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
    std::string rrule = "FREQ=YEARLY;WKST=SU;BYDAY=2MO,3WE,4FR;BYMONTH=6,7,8";
    const auto value = GetRule(event);

    EXPECT_EQ(value, rrule);
}

HWTEST_F(EventRecurrenceRuleTest, BuildValueEventRecurrenceRule, testing::ext::TestSize.Level1)
{
    Event event;
    event.identifier = std::make_optional<std::string>("1111");
    event.isLunar = std::make_optional<bool>(true);
    RecurrenceRule recurrenceRule;
    recurrenceRule.recurrenceFrequency = YEARLY;
    recurrenceRule.daysOfWeek = {1, 3, 5};
    recurrenceRule.weeksOfMonth = {2, 3, 4};
    recurrenceRule.monthsOfYear = {6, 7, 8};
    recurrenceRule.excludedDates = {1727254841000};
    event.recurrenceRule = std::make_optional<RecurrenceRule>(recurrenceRule);
    std::string rrule = "FREQ=YEARLY;WKST=SU;BYDAY=2MO,3WE,4FR;BYMONTH=6,7,8";
    std::string excludedDateStr = "20240925T090041Z";
    DataShare::DataShareValuesBucket newShareValuesBucket;
    newShareValuesBucket.Put("rrule", rrule);
    newShareValuesBucket.Put("exdate", excludedDateStr);
    auto shareValuesBucket = BuildValueEvent(event, 0, 0, false);
    auto itRrule = shareValuesBucket.valuesMap.find("rrule");
    auto *itRruleValue = std::get_if<std::string>(&itRrule->second);
    std::string rruleVal = *itRruleValue;
    auto itExcludedDate = shareValuesBucket.valuesMap.find("exdate");
    auto *itExcludedDateValue = std::get_if<std::string>(&itExcludedDate->second);
    std::string excludedDate = *itExcludedDateValue;
    EXPECT_EQ(rrule, rruleVal);
    EXPECT_EQ(excludedDateStr, excludedDate);
}

}