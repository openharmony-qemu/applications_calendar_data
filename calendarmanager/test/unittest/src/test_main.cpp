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

#include "gtest/gtest.h"
#include "calendar_log.h"
#include "get_self_permissions.h"
#include "data_share_helper_manager.h"
#include "calendar_env.h"
#include "accesstoken_kit.h"
#include "datashare_helper.h"
#include "iservice_registry.h"
#include "system_ability_definition.h"
#include "token_setproc.h"

using namespace testing::ext;
using namespace OHOS::Security::AccessToken;
using namespace OHOS::DataShare;
namespace {
    std::string DATA_SHARE_URI = "datashare:///calendardata";
}

namespace OHOS::CalendarApi {
std::shared_ptr<DataShare::DataShareHelper> CreateDataShareHelper(int32_t systemAbilityId, const std::string& uri)
{
    LOG_INFO("CreateDataShareHelper start");
    auto saManager = SystemAbilityManagerClient::GetInstance().GetSystemAbilityManager();
    if (saManager == nullptr) {
        LOG_ERROR("GetSystemAbilityManager get samgr failed.");
        return nullptr;
    }
    auto remoteObj = saManager->GetSystemAbility(systemAbilityId);
    while (remoteObj == nullptr) {
        LOG_ERROR("GetSystemAbility service failed.");
        return nullptr;
    }
    LOG_INFO("CreateDataShareHelper %{public}s", uri.c_str());
    return DataShare::DataShareHelper::Creator(remoteObj, uri);
}

void InitEnv(void)
{
    constexpr int storageManagerId = 5003;
    vector<string> perms;
    perms.push_back("ohos.permission.READ_CALENDAR");
    perms.push_back("ohos.permission.WRITE_CALENDAR");
    uint64_t tokenId = 0;
    SetAccessTokenPermission("calendar_manager_test", perms, tokenId);
    ASSERT_TRUE(tokenId != 0);
    CalendarEnv::GetInstance().Init("ohos.calendar_manager_test.demo", tokenId);
    auto helper = CreateDataShareHelper(storageManagerId, DATA_SHARE_URI);
    ASSERT_TRUE(helper != nullptr);
    DataShareHelperManager::GetInstance().SetDataShareHelper(helper);
    LOG_INFO("SetUpTestCase end");
}

void UnInitEnv(void)
{
    auto tokenId = AccessTokenKit::GetHapTokenID(100, "ohos.datashareclienttest.demo", 0);
    AccessTokenKit::DeleteToken(tokenId);
}
} // namespace OHOS::CalendarApi

class GlobalEnvironment : public testing::Environment {
public:
    virtual void SetUp()
    {
        OHOS::CalendarApi::InitEnv();
    }
    virtual void TearDown()
    {
        OHOS::CalendarApi::UnInitEnv();
    }
};


int main(int argc, char **argv)
{
    testing::GTEST_FLAG(output) = "xml:./";
    ::testing::InitGoogleTest(&argc, argv);
    testing::AddGlobalTestEnvironment(new GlobalEnvironment);
    return RUN_ALL_TESTS();
}