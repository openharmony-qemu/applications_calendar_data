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
#include "data_share_helper_manager.h"

namespace OHOS::CalendarApi::Native {
class DataShareHelperManagerTest : public testing::Test {
public:
    /* SetUpTestCase:The preset action of the test suite is executed before the first TestCase */
    static void SetUpTestSuite(void)
    {
        // save helper
        helper = DataShareHelperManager::GetInstance().GetDataShareHelper();
    }

    /* TearDownTestCase:The test suite cleanup action is executed after the last TestCase */
    static void TearDownTestSuite(void)
    {
        DataShareHelperManager::GetInstance().SetDataShareHelper(helper);
    }
    /* SetUp:Execute before each test case */
    void SetUp()
    {
    }

    /* TearDown:Execute after each test case */
    void TearDown()
    {
    }

    static std::shared_ptr<DataShare::DataShareHelper> helper;
};

std::shared_ptr<DataShare::DataShareHelper> DataShareHelperManagerTest::helper = nullptr;

HWTEST_F(DataShareHelperManagerTest, Insert_test_001, testing::ext::TestSize.Level1)
{
    OHOS::Uri testUrl("");
    DataShare::DataShareValuesBucket value;
    DataShareHelperManager::GetInstance().SetDataShareHelper(nullptr);
    auto ret = DataShareHelperManager::GetInstance().Insert(testUrl, value);
    ASSERT_TRUE(ret == -1);
}

HWTEST_F(DataShareHelperManagerTest, Update_test_001, testing::ext::TestSize.Level1)
{
    OHOS::Uri testUrl("");
    DataShare::DataSharePredicates predicates;
    DataShare::DataShareValuesBucket value;
    DataShareHelperManager::GetInstance().SetDataShareHelper(nullptr);
    auto ret = DataShareHelperManager::GetInstance().Update(testUrl, predicates, value);
    ASSERT_TRUE(ret == -1);
}

HWTEST_F(DataShareHelperManagerTest, Delete_test_001, testing::ext::TestSize.Level1)
{
    OHOS::Uri testUrl("");
    DataShare::DataSharePredicates predicates;
    DataShareHelperManager::GetInstance().SetDataShareHelper(nullptr);
    auto ret = DataShareHelperManager::GetInstance().Delete(testUrl, predicates);
    ASSERT_TRUE(ret == -1);
}

HWTEST_F(DataShareHelperManagerTest, Query_test_001, testing::ext::TestSize.Level1)
{
    OHOS::Uri testUrl("");
    DataShare::DataSharePredicates predicates;
    std::vector<std::string> columns;
    DataShare::DatashareBusinessError error;
    DataShareHelperManager::GetInstance().SetDataShareHelper(nullptr);
    auto ret = DataShareHelperManager::GetInstance().Query(testUrl, predicates, columns, &error);
    ASSERT_TRUE(ret == nullptr);
}
}