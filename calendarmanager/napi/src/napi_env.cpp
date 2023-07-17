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


#include "napi_env.h"
#include "calendar_log.h"
#include "calendar_env.h"
#include "ability.h"
#include "ability_context.h"
#include "context.h"
#include "napi_base_context.h"
#include "data_share_helper_manager.h"
#include "datashare_helper.h"
#include "datashare_predicates.h"

#include "ipc_skeleton.h"

namespace OHOS::CalendarApi {

bool IsStageMode(napi_env env, napi_value value)
{
    bool stageMode = true;
    napi_status status = OHOS::AbilityRuntime::IsStageContext(env, value, stageMode);
    if (status != napi_ok) {
        LOG_ERROR("IsStageContext call failed %{public}d.", status);
    }
    return stageMode;
}

napi_status CalendarEnvNapi::GetContext(napi_env env)
{
    napi_value global;
    LOG_DEBUG("napi_get_global");
    napi_status status = napi_get_global(env, &global);
    if (status != napi_ok) {
        LOG_ERROR("GetDataShareHelper napi_get_global != napi_ok");
    }
    napi_value globalThis;
    status = napi_get_named_property(env, global, "globalThis", &globalThis);
    if (status != napi_ok) {
        LOG_ERROR("GetDataShareHelper napi_get_globalThis != napi_ok");
    }
    napi_value abilityContext = nullptr;
    status = napi_get_named_property(env, globalThis, "abilityContext", &abilityContext);
    if (status != napi_ok) {
        LOG_ERROR("GetDataShareHelper napi_get_abilityContext != napi_ok");
    }
    if (!IsStageMode(env, abilityContext)) {
        auto ability = OHOS::AbilityRuntime::GetCurrentAbility(env);
        if (ability == nullptr) {
            LOG_ERROR("GetCurrentAbility ability == nullptr.");
            return napi_generic_failure;
        }
        m_context = ability->GetAbilityContext();
    } else {
        m_context = OHOS::AbilityRuntime::GetStageModeContext(env, abilityContext);
        if (m_context == nullptr) {
            LOG_ERROR("GetStageModeContext contextRtm == nullptr.");
            return napi_generic_failure;
        }
    }
    if (m_context == nullptr) {
        LOG_ERROR("GetContext failed. context is nullptr.");
        return napi_generic_failure;
    }
    return napi_ok;
}

void CalendarEnvNapi::Init(napi_env env)
{
    const std::string CALENDAR_DATA_URI = "datashare:///calendardata";
    if (hasInited) {
        return;
    }
    LOG_INFO("CalendarEnvNapi Init.");
    auto status = GetContext(env);
    if (status != napi_ok) {
        return;
    }
    std::string bundleName = m_context->GetBundleName();
    uint64_t tokenId = IPCSkeleton::GetSelfTokenID();
    CalendarEnv::GetInstance().Init(bundleName, tokenId);
    auto dataShareHelper = DataShare::DataShareHelper::Creator(m_context->GetToken(), CALENDAR_DATA_URI);
    DataShareHelperManager::GetInstance().SetDataShareHelper(dataShareHelper);
    hasInited = true;
}
};
