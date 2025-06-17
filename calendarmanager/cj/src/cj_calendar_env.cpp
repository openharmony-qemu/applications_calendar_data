/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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


#include "cj_calendar_env.h"
#include "calendar_log.h"
#include "calendar_env.h"
#include "ability.h"
#include "ability_context.h"
#include "context.h"
#include "napi_base_context.h"
#include "data_share_helper_manager.h"
#include "datashare_helper.h"
#include "datashare_predicates.h"
#include "accesstoken_kit.h"

#include "ipc_skeleton.h"

namespace OHOS::CalendarApi {

void CJCalendarEnv::Init(std::shared_ptr<OHOS::AbilityRuntime::Context> context)
{
    if (hasInited) {
        return;
    }
    LOG_INFO("CJCalendarEnv Init.");
    m_context = context;
    if (m_context == nullptr) {
        LOG_ERROR("CJCalendarEnv::Init error");
        return;
    }
    std::string bundleName = m_context->GetBundleName();
    uint64_t tokenId = IPCSkeleton::GetSelfTokenID();
    CalendarEnv::GetInstance().Init(bundleName, tokenId);
    hasInited = true;
}

std::shared_ptr<OHOS::AbilityRuntime::Context> CJCalendarEnv::getContext()
{
    return m_context;
}
};
