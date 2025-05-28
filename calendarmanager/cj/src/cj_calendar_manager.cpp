/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include "ability_runtime/cj_ability_context.h"
#include "calendar_manager_ffi.h"
#include "cj_calendar_manager.h"
#include "cj_calendar.h"
#include "cj_event_filter.h"
#include "native/ffi_remote_data.h"
#include "ipc_skeleton.h"
#include "calendar_log.h"
#include "native_calendar.h"
#include "native_util.h"
#include "native_calendar_manager.h"
#include "calendar_env.h"

using namespace OHOS;
using namespace OHOS::AbilityRuntime;
using namespace OHOS::CalendarApi;
using namespace OHOS::FFI;
using namespace OHOS::DataShare;
using namespace OHOS::AppExecFwk;
static const int INVALID_EVENT_ID = -1;

namespace OHOS {
namespace CalendarApi {
void CJCalendarManager::GetCalendarManager(int64_t contextId, int32_t* errcode)
{
    sptr<CJAbilityContext> context = OHOS::FFI::FFIData::GetData<CJAbilityContext>(contextId);
    if (context == nullptr) {
        LOG_ERROR("Context is nullptr");
        *errcode = -1;
    }

    std::string bundleName = context->GetBundleName();
    uint64_t tokenId = IPCSkeleton::GetSelfTokenID();
    CalendarEnv::GetInstance().Init(bundleName, tokenId);
}

int64_t CJCalendarManager::CreateCalendar(CCalendarAccount calendarAccount, int32_t* errcode)
{
    CalendarAccount account;
    account.name = calendarAccount.name;
    account.type = calendarAccount.type;
    account.displayName = calendarAccount.displayName;

    auto calendar_ = Native::CalendarManager::GetInstance().CreateCalendar(account);
    if (calendar_ == nullptr) {
        LOG_ERROR("calendar_ is nullptr");
        *errcode = -1;
    }
    auto instance = OHOS::FFI::FFIData::Create<CJCalendar>(calendar_);
    return instance->GetID();
}

void CJCalendarManager::DeleteCalendar(int64_t calendarId, int32_t* errcode)
{
    auto instance = FFIData::GetData<CJCalendar>(calendarId);
    if (instance == nullptr) {
        LOG_ERROR("CJCalendar is nullptr");
        *errcode = -1;
    }
    auto nativeCalendar = instance->calendar_;
    bool result = Native::CalendarManager::GetInstance().DeleteCalendar(*(nativeCalendar.get()));
    if (result) {
        LOG_ERROR("deleteCalendar failed");
        *errcode = -1;
    }
}

int64_t CJCalendarManager::GetCalendar(CCalendarAccount calendarAccount, int32_t* errcode)
{
    CalendarAccount account;
    account.name = calendarAccount.name;
    account.type = calendarAccount.type;
    account.displayName = calendarAccount.displayName;
    auto calendar_ = Native::CalendarManager::GetInstance().GetCalendar(account);
    if (calendar_ == nullptr) {
        LOG_ERROR("calendar_ is nullptr");
        *errcode = -1;
    }
    auto instance = OHOS::FFI::FFIData::Create<CJCalendar>(calendar_);
    return instance->GetID();
}

CArrI64 CJCalendarManager::GetAllCalendars(int32_t* errcode)
{
    std::vector<int64_t> calendarIds;
    auto nativeCalendars = Native::CJNativeCalendarManager::GetInstance().GetAllCalendars();
    CArrI64 ret = {.head = nullptr, .size = 0};
    if (nativeCalendars.empty()) {
        LOG_ERROR("nativeCalendars is empty");
        *errcode = -1;
        return ret;
    }
    auto size = nativeCalendars.size();
    auto arr = static_cast<int64_t*>(malloc(size * sizeof(int64_t)*size));
    if (arr == nullptr) {
        LOG_ERROR("arr is nullptr");
        *errcode = -1;
        return ret;
    }
    
    int64_t i = 0;
    for (auto &nativeCalendar : nativeCalendars) {
        int64_t calendarId = nativeCalendar->GetId();
        arr[i] = calendarId;
        i++;
    }
    ret.head = arr;
    ret.size = static_cast<int64_t>(size);
    return ret;
}

int64_t CJCalendarManager::EditerEvent(int64_t contextId, char* eventstr, int32_t* errcode)
{
    sptr<CJAbilityContext> abilityContext = FFIData::GetData<CJAbilityContext>(contextId);
    if (abilityContext == nullptr) {
        LOG_ERROR("Context is nullptr");
        *errcode = -1;
    }

    int32_t _sessionId = 0;
    Ace::UIContent *_uiContent = nullptr;
    std::string event = std::to_string(eventstr);
    int64_t id = 0;

    _uiContent = abilityContext->GetUIContent();
    AAFwk::Want want;
    want.SetElementName("com.ohos.calendardata", "EditorUIExtensionAbility");
    const std::string uiExtType = "sys/commonUI";
    want.SetParam("ability.want.params.uiExtensionType", uiExtType);
    want.SetParam("event", event);
    Ace::ModalUIExtensionCallbacks callbacks;

    callbacks = {
        .onRelease = [_uiContent, _sessionId](int32_t code) {
            LOG_INFO("editEvent onRelease callback.");
            _uiContent->CloseModalUIExtension(_sessionId);
            LOG_INFO("editEvent onRelease done.");
        },
        .onResult = [_uiContent, _sessionId](int32_t code, const AAFwk::Want &wantRes) {
            auto eventId = wantRes.GetIntParam("eventId", INVALID_EVENT_ID);
            LOG_INFO("editEvent onResult. eventId=%{public}d", eventId);
            id = eventId;
        },
        .onReceive = [_uiContent, _sessionId](const AAFwk::WantParams &wantParams) {
            LOG_INFO("editEvent onReceive.");
        },
        .onError = [_uiContent, _sessionId](int32_t code, const std::string &event, const std::string &msg) {
            LOG_ERROR("editEvent onError.%{public}s", msg.c_str());
            uiContent->CloseModalUIExtension(_sessionId);
        },
        .onRemoteReady = [_uiContent, _sessionId](const std::shared_ptr<Ace::ModalUIExtensionProxy> &proxy) {
            LOG_INFO("editEvent onRemoteReady.");
        },
        .onDestroy = [_uiContent, _sessionId]{
            LOG_INFO("editEvent onDestroy.");
        },
    };
    Ace::ModalUIExtensionConfig config;
    config = {
        .isProhibitBack = false,
    };
    _sessionId = _uiContent->CreateModalUIExtension(want, callbacks, config);

    return id;
}

}
}