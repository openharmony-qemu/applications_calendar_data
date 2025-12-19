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
#include <random>
#include "calendar_log.h"
#include "native_calendar_manager.h"

namespace OHOS::CalendarApi::Native {
class CalendarManagerTest : public testing::Test {
public:
    /* SetUpTestCase:The preset action of the test suite is executed before the first TestCase */
    static void SetUpTestSuite(void) {}

    /* TearDownTestCase:The test suite cleanup action is executed after the last TestCase */
    static void TearDownTestSuite(void) {}
    /* SetUp:Execute before each test case */
    void SetUp()
    {
        CalendarManager::GetInstance().DeleteAllCalendars();
    }

    /* TearDown:Execute after each test case */
    void TearDown()
    {
    }
};

HWTEST_F(CalendarManagerTest, getCalendar_with_not_account, testing::ext::TestSize.Level0)
{
    auto result = CalendarManager::GetInstance().GetCalendar(std::nullopt);
    auto calendar = result.value();
    ASSERT_TRUE(calendar != nullptr);
    auto account = calendar->GetAccount();
    EXPECT_TRUE(CalendarManager::IsDefaultAccount(calendar->GetAccount()));
}

HWTEST_F(CalendarManagerTest, getCalendar_which_no_exist, testing::ext::TestSize.Level1)
{
    CalendarAccount test_account {
        "name_getCalendar_which_no_exist",
        "local",
        "displayName_getCalendar_which_no_exist"
    };
    auto result = CalendarManager::GetInstance().GetCalendar(test_account);
    ASSERT_EQ(result.is_err(), true);
    ASSERT_EQ(result.error().code, QUERY_RESULT_EMPTY);
}

HWTEST_F(CalendarManagerTest, getCalendar_test_exist, testing::ext::TestSize.Level1)
{
    CalendarAccount test_account {
        "name_getCalendar_test_exist",
        "local",
    };
    auto result = CalendarManager::GetInstance().GetCalendar(test_account);
    std::shared_ptr<Calendar> calendar;
    ASSERT_TRUE(result.is_err());
    if (result.is_err()) {
        result = CalendarManager::GetInstance().CreateCalendar(test_account);
        calendar = result.value();
        ASSERT_TRUE(calendar);
    }
    auto accountExpect = calendar->GetAccount();
    EXPECT_EQ(accountExpect.name, test_account.name);
    EXPECT_EQ(accountExpect.type, test_account.type);
}

HWTEST_F(CalendarManagerTest, getCalendar_test_no_exist, testing::ext::TestSize.Level1)
{
    CalendarAccount test_account {
        "name_getCalendar_test_exist",
        "local",
    };
    auto result = CalendarManager::GetInstance().GetCalendar(test_account);;
    ASSERT_TRUE(result.is_err());
    EXPECT_EQ(result.error().code, QUERY_RESULT_EMPTY);
}

HWTEST_F(CalendarManagerTest, deleteCalendar_test_no_exist, testing::ext::TestSize.Level1)
{
    auto error = std::make_shared<Error>();
    CalendarAccount test_account {
        "name_getCalendar_test_exist",
        "local",
    };
    auto calendarTest = new Calendar(test_account, 0);
    auto result = CalendarManager::GetInstance().DeleteCalendar(*calendarTest);
    EXPECT_TRUE(result.is_ok());
    EXPECT_EQ(result.value(), 0);
    if (calendarTest) {
        delete calendarTest;
        calendarTest = nullptr;
    }
    EXPECT_EQ(calendarTest, nullptr);
}

HWTEST_F(CalendarManagerTest, createCalendar_which_not_exist, testing::ext::TestSize.Level1)
{
    CalendarAccount test_account {
        "name_createCalendar_which_not_exist",
        "local",
    };
    std::shared_ptr<Calendar> calendar;
    auto getResult = CalendarManager::GetInstance().GetCalendar(test_account);
    ASSERT_FALSE(getResult.is_ok());
    ASSERT_EQ(getResult.error().code, QUERY_RESULT_EMPTY);
    auto createRet = CalendarManager::GetInstance().CreateCalendar(test_account);
    ASSERT_TRUE(createRet.is_ok());
    calendar = createRet.value();
    ASSERT_TRUE(calendar);
    auto accountExpect = calendar->GetAccount();
    EXPECT_EQ(accountExpect.name, test_account.name);
    EXPECT_EQ(accountExpect.type, test_account.type);
}

HWTEST_F(CalendarManagerTest, createCalendar_which_already_exist, testing::ext::TestSize.Level1)
{
    CalendarAccount test_account {
        "createCalendar_which_already_exist",
        "local",
        "displayName_unit_test"
    };
    std::shared_ptr<Calendar> calendar;
    auto result = CalendarManager::GetInstance().GetCalendar(test_account);
    ASSERT_FALSE(result.is_ok());
    auto createRet = CalendarManager::GetInstance().CreateCalendar(test_account);
    ASSERT_TRUE(createRet.is_ok());
    calendar = createRet.value();
    ASSERT_TRUE(calendar);
    auto newCalendar = CalendarManager::GetInstance().CreateCalendar(test_account);
    ASSERT_TRUE(newCalendar.is_ok()); // todo is bug!!
}

HWTEST_F(CalendarManagerTest, getAllCalendars_test_1, testing::ext::TestSize.Level1)
{
    CalendarAccount test_account {
        "createAllCalendars_which_already_exist_1",
        "local",
        "displayName_unit_test"
    };
    CalendarAccount test_account1 {
        "createAllCalendars_which_already_exist_2",
        "local",
        "displayName_unit_test"
    };
    CalendarManager::GetInstance().CreateCalendar(test_account);
    CalendarManager::GetInstance().CreateCalendar(test_account1);

    auto calendarsRet = CalendarManager::GetInstance().GetAllCalendars();
    ASSERT_TRUE(calendarsRet.is_ok());
    auto calendars = calendarsRet.value();
    ASSERT_EQ(calendars.size(), 3); // 3 is include defalut calendar
}

HWTEST_F(CalendarManagerTest, getAllCalendars_only_default_calendar, testing::ext::TestSize.Level1)
{
    auto calendarsRet = CalendarManager::GetInstance().GetAllCalendars();
    ASSERT_TRUE(calendarsRet.is_ok());
    auto calendars =calendarsRet.value();
    ASSERT_EQ(calendars.size(), 1); // 1 is defalut calendar
    auto calendar = calendars.at(0);
    ASSERT_TRUE(calendar != nullptr);
    auto account = calendar->GetAccount();
    EXPECT_TRUE(CalendarManager::IsDefaultAccount(calendar->GetAccount()));
}

HWTEST_F(CalendarManagerTest, getAccount_test_1, testing::ext::TestSize.Level1)
{
    CalendarAccount test_account {
        "name_getAccount_test_1",
        "local",
        "displayName_getAccount_test_1"
    };
    std::shared_ptr<Calendar> calendar;
    auto result = CalendarManager::GetInstance().GetCalendar(test_account);
    ASSERT_TRUE(result.is_err());
    ASSERT_EQ(result.error().code, QUERY_RESULT_EMPTY);
    auto createRet = CalendarManager::GetInstance().CreateCalendar(test_account);
    ASSERT_TRUE(createRet.is_ok());
    auto newCalendar = CalendarManager::GetInstance().CreateCalendar(test_account);
    ASSERT_TRUE(newCalendar.is_ok()); // todo is bug!!
}
}