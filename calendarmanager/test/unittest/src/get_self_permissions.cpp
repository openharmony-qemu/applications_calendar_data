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
#include "get_self_permissions.h"

#include <thread>

#include "accesstoken_kit.h"
#include "calendar_log.h"
#include "nativetoken_kit.h"
#include "token_setproc.h"

namespace OHOS::CalendarApi {
void SetAccessTokenPermission(const std::string &processName,
    const std::vector<std::string> &permission, uint64_t &tokenId)
{
    auto perms = std::make_unique<const char *[]>(permission.size());
    for (size_t i = 0; i < permission.size(); i++) {
        perms[i] = permission[i].c_str();
    }

    NativeTokenInfoParams infoInstance = {
        .dcapsNum = 0,
        .permsNum = permission.size(),
        .aclsNum = 0,
        .dcaps = nullptr,
        .perms = perms.get(),
        .acls = nullptr,
        .processName = processName.c_str(),
        .aplStr = "normal",
    };
    tokenId = GetAccessTokenId(&infoInstance);
    if (tokenId == 0) {
        LOG_ERROR("Get Acess Token Id Failed");
        return;
    }
    int ret = SetSelfTokenID(tokenId);
    if (ret != 0) {
        LOG_ERROR("Set Acess Token Id Failed");
        return;
    }
    ret = Security::AccessToken::AccessTokenKit::ReloadNativeTokenInfo();
    if (ret < 0) {
        LOG_ERROR("Reload Native Token Info Failed");
        return;
    }
}
} // namespace OHOS::CalendarApi

