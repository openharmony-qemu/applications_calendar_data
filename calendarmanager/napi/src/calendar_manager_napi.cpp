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

#include "calendar_manager_napi.h"
#include <optional>
#include "report_hievent_manager.h"

using namespace OHOS::AppExecFwk;
using namespace OHOS::DataShare;
static const int INVALID_EVENT_ID = -1;
static const int ARGS_INDEX_ONE = 1;
static const int ARGS_INDEX_TWO = 2;
static const int ARGS_INDEX_THREE = 3;

namespace {
    const std::string CALENDAR_MANAGER_CLASS_NAME = "CalendarManager";
    static thread_local napi_ref g_constructorRef = nullptr;
    constexpr uint32_t INITIAL_REFCOUNT = 1;
}
namespace OHOS::CalendarApi {
napi_value CalendarManagerNapi::CreateCalendar(napi_env env, napi_callback_info info)
{
    LOG_INFO("napi CreateCalendar called");
    struct CreateCalendarContext : public ContextBase {
        CalendarAccount account;
        CalendarNapi *calendar;
        int id;
        napi_ref ref = nullptr;
    };
    auto ctxt = std::make_shared<CreateCalendarContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        // required 1 arguments :: <CalendarAccount>
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 1, PARAMETER_INVALID, "invalid arguments!");
        NapiUtil::GetValue(env, argv[0], ctxt->account);
        CHECK_STATUS_RETURN_VOID(ctxt, PARAMETER_VALUE_OUTRANGE, "invalid arg[0], i.e. invalid keys!");
        ctxt->ref = NapiUtil::NewWithRef(env, argc, argv, reinterpret_cast<void**>(&ctxt->calendar),
            CalendarNapi::Constructor(env));
    };
    ctxt->GetCbInfo(env, info, input);

    auto execute = [ctxt]() {
        auto beginTime = Native::ReportHiEventManager::GetInstance().GetCurrentTime();
        auto result = Native::CalendarManager::GetInstance().CreateCalendar(ctxt->account);
        Native::ReportHiEventManager::GetInstance()
            .OnApiCallEnd("CreateCalendar", result.IsOk(), beginTime);
        if (result.IsErr()) {
            ctxt->error = result.GetError();
            ctxt->status = napi_generic_failure;
            CHECK_ERRCODE_RETURN_VOID(ctxt, "CreateCalendar failed!");
        }
        auto nativteCalendar = result.GetValue();
        ctxt->calendar->SetNative(nativteCalendar);
        ctxt->id = nativteCalendar->GetId();
    };
    auto output = [env, ctxt](napi_value& result) {
        ctxt->status = napi_get_reference_value(env, ctxt->ref, &result);
        CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "CreateCalendar output get ref value failed");
        ctxt->status = NapiUtil::SetNamedProperty(env, "id", ctxt->id, result);
        CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "CreateCalendar SetNamedProperty id failed");
        ctxt->status = napi_delete_reference(env, ctxt->ref);
        CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "CreateCalendar output del ref failed");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

napi_value CalendarManagerNapi::DeleteCalendar(napi_env env, napi_callback_info info)
{
    LOG_INFO("napi DeleteCalendar called");
    struct DelCalendarContext : public ContextBase {
        CalendarAccount account;
        CalendarNapi *calendar;
        bool delResult = false;
    };
    auto ctxt = std::make_shared<DelCalendarContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        // required 1 arguments :: <Calendar>
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 1, PARAMETER_INVALID, "invalid arguments!");
        napi_valuetype type = napi_undefined;
        napi_typeof(env, argv[0], &type);
        CHECK_ARGS_RETURN_VOID(ctxt, type == napi_object, PARAMETER_INVALID, "type error!");
        ctxt->status = CalendarNapi::ToJson(env, argv[0], ctxt->calendar);
        CHECK_STATUS_RETURN_VOID(ctxt, PARAMETER_INVALID, "invalid arg[0], i.e. invalid keys!");
    };
    ctxt->GetCbInfo(env, info, input);

    auto execute = [ctxt]() {
        CHECK_RETURN_VOID(ctxt->calendar, "calendar is nullptr");
        auto nativeCalendar = ctxt->calendar->GetNative();
        CHECK_RETURN_VOID(nativeCalendar, "calendar is nullptr");
        auto beginTime = Native::ReportHiEventManager::GetInstance().GetCurrentTime();
        auto result = Native::CalendarManager::GetInstance().DeleteCalendar(*(nativeCalendar.get()));
        ctxt->delResult = (result.IsOk()) ? result.GetValue() : false;
        Native::ReportHiEventManager::GetInstance().OnApiCallEnd("DeleteCalendar", ctxt->delResult, beginTime);
        CHECK_RETURN_VOID(ctxt->delResult, "DeleteCalendar failed!");
    };
    auto output = [env, ctxt](napi_value& result) {
        NapiUtil::SetValue(env, ctxt->delResult, result);
        CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "output del ref failed");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

struct GetCalendarContext : public ContextBase {
    std::optional<CalendarAccount> account;
    CalendarNapi *calendar = nullptr;
    napi_ref ref = nullptr;
    int id = -1;

    void GetCbInfo(napi_env env, napi_callback_info info)
    {
        auto input = [env, this](size_t argc, napi_value* argv) {
            // required at least 1 arguments :: <CalendarAccount>
            CHECK_ARGS_RETURN_VOID(this, argc <= 1, PARAMETER_INVALID, "invalid arguments!");
            if (argc == 0) {
                this->account = std::nullopt;
            } else {
                CalendarAccount tmpAccount;
                NapiUtil::GetValue(env, argv[0], tmpAccount);
                this->account = tmpAccount;
            }
            CHECK_STATUS_RETURN_VOID(this, PARAMETER_VALUE_OUTRANGE, "invalid arg[0], i.e. invalid keys!");
            ref = NapiUtil::NewWithRef(env, argc, argv, reinterpret_cast<void**>(&calendar),
                CalendarNapi::Constructor(env));
        };
        LOG_DEBUG("call ContextBase::GetCbInfo");
        ContextBase::GetCbInfo(env, info, input);
    }
};

napi_value CalendarManagerNapi::GetCalendar(napi_env env, napi_callback_info info)
{
    LOG_DEBUG("GetCalendar in");
    auto ctxt = std::make_shared<GetCalendarContext>();
    ctxt->GetCbInfo(env, info);
    
    auto execute = [ctxt]() {
        auto result = Native::CalendarManager::GetInstance().GetCalendar(ctxt->account);
        if (result.IsErr()) {
            ctxt->error = result.GetError();
            ctxt->status = napi_generic_failure;
            return;
        }
        auto nativteCalendar = result.GetValue();
        if (ctxt->calendar != nullptr) {
            ctxt->calendar->SetNative(nativteCalendar);
        }
        ctxt->id = nativteCalendar->GetId();
    };
    auto output = [env, ctxt](napi_value& result) {
        ctxt->status = napi_get_reference_value(env, ctxt->ref, &result);
        CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "GetCalendar output get ref value failed");
        ctxt->status = NapiUtil::SetNamedProperty(env, "id", ctxt->id, result);
        CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "GetCalendar SetNamedProperty id failed");
        ctxt->status = napi_delete_reference(env, ctxt->ref);
        CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "GetCalendar output del ref failed");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

napi_value CalendarManagerNapi::GetAllCalendars(napi_env env, napi_callback_info info)
{
    LOG_DEBUG("napi GetAllCalendars called");
    struct GetAllCalendarContext : public ContextBase {
        napi_callback_info info;
        std::vector<std::shared_ptr<Native::Calendar>> nativteCalendars;
    };

    auto ctxt = std::make_shared<GetAllCalendarContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 0, PARAMETER_INVALID, "invalid arguments!");
    };
    ctxt->GetCbInfo(env, info, input);

    auto execute = [env, ctxt]() {
        auto result = Native::CalendarManager::GetInstance().GetAllCalendars();
        if (result.IsErr()) {
            LOG_ERROR("GetAllCalendar error, error code: %{public}d", ctxt->error.code);
        } else {
            ctxt->nativteCalendars = result.GetValue();
        }
    };

    auto output = [env, ctxt](napi_value& result) {
        size_t argc = 0;
        napi_value* argv = nullptr;
        int index = 0;
        ctxt->status = napi_create_array_with_length(env, ctxt->nativteCalendars.size(), &result);
        for (auto &calendar : ctxt->nativteCalendars) {
            CalendarNapi *calendarNapi = nullptr;
            napi_value object = nullptr;
            ctxt->status = napi_new_instance(env, CalendarNapi::Constructor(env), argc, argv, &object);
            CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "new instance failed");
            ctxt->status = napi_unwrap(env, object, reinterpret_cast<void**>(&calendarNapi));
            CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "unwrap failed");
            CHECK_RETURN_VOID(calendarNapi != nullptr, "new CalendarNapi failed!");
            calendarNapi->SetNative(calendar);
            CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "napi_get_reference_value failed");
            ctxt->status = NapiUtil::SetNamedProperty(env, "id", calendar->GetId(), object);
            CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "SetNamedProperty id failed");
            ctxt->status = napi_set_element(env, result, index++, object);
            CHECK_STATUS_RETURN_VOID(ctxt, INTERNAL_ERROR, "napi_set_element failed!");
        }
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

napi_value GetCalendarManager(napi_env env, napi_callback_info info)
{
    LOG_INFO("napi GetCalendarManager called");
    const int argsOne = 1;
    napi_value result = nullptr;
    napi_value cons = nullptr;
    size_t requireArgc = argsOne;
    size_t argc = argsOne;
    napi_value args[argsOne] = {nullptr};
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok) {
        return nullptr;
    }

    if (argc > requireArgc || napi_get_reference_value(env, g_constructorRef, &cons) != napi_ok) {
        return nullptr;
    }

    if (napi_new_instance(env, cons, argsOne, args, &result) != napi_ok) {
        return nullptr;
    }
    CalendarManagerNapi *calendarManager = nullptr;
    if (napi_unwrap(env, result, (void **)&calendarManager) != napi_ok) {
        LOG_ERROR("Faild to get fileAccessHelper");
        return nullptr;
    }

    if (calendarManager == nullptr) {
        LOG_ERROR("fileAccessHelper is nullptr");
        return nullptr;
    }
    return result;
}

napi_value CalendarManagerNapi::EditEvent(napi_env env, napi_callback_info info)
{
    auto ctxt = std::make_shared<EditEventContext>();
    napi_value jsContext = nullptr;
    auto input = [env, ctxt, &jsContext](size_t argc, napi_value* argv) {
        CHECK_ARGS_RETURN_VOID(ctxt, argc == ARGS_INDEX_THREE, PARAMETER_INVALID, "invalid arguments!");
        jsContext = argv[0];
        ctxt->status = NapiUtil::GetValue(env, argv[ARGS_INDEX_ONE], ctxt->event);
        CHECK_STATUS_RETURN_VOID(ctxt, PARAMETER_INVALID, "invalid event JSON");
        ctxt->status = NapiUtil::GetValue(env, argv[ARGS_INDEX_TWO], ctxt->caller);
        CHECK_STATUS_RETURN_VOID(ctxt, PARAMETER_INVALID, "invalid caller");
    };
    ctxt->GetCbInfo(env, info, input, true);
    if (ctxt->status != napi_ok || ctxt->error.code != NO_ERROR) {
        return LaunchEditorPage(env, ctxt);
    }
    bool isStageMode = false;
    auto status = OHOS::AbilityRuntime::IsStageContext(env, jsContext, isStageMode);
    if (status != napi_ok || !isStageMode) {
        ctxt->error = {"editEvent requires a Stage UIAbility context", PARAMETER_INVALID};
        return LaunchEditorPage(env, ctxt);
    }
    auto stageContext = OHOS::AbilityRuntime::GetStageModeContext(env, jsContext);
    auto abilityContext = OHOS::AbilityRuntime::Context::ConvertTo<AbilityRuntime::AbilityContext>(stageContext);
    if (abilityContext == nullptr) {
        ctxt->error = {"editEvent requires a UIAbility context", PARAMETER_INVALID};
        return LaunchEditorPage(env, ctxt);
    }
    ctxt->hostContext = abilityContext;
    ctxt->_uiContent = abilityContext->GetUIContent();
    return LaunchEditorPage(env, ctxt);
}

void CalendarManagerNapi::CleanupEditorEnvironment(void *data)
{
    std::unique_ptr<EditorCleanup> cleanup(static_cast<EditorCleanup *>(data));
    auto environment = cleanup->environment;
    std::lock_guard<std::mutex> envLock(environment->mutex);
    environment->alive = false;
    environment->env = nullptr;
    auto ctxt = cleanup->context.lock();
    if (ctxt == nullptr) {
        return;
    }
    std::lock_guard<std::mutex> lock(ctxt->mutex);
    ctxt->cancelled = true;
    ++ctxt->generation;
    ctxt->completionQueued = false;
    ctxt->deferred = nullptr;
    ctxt->cleanup = nullptr;
    ctxt->_uiContent = nullptr;
    ctxt->closed = true;
}

void CalendarManagerNapi::CloseEditorSession(const std::shared_ptr<EditEventContext> &ctxt)
{
    std::lock_guard<std::mutex> lock(ctxt->mutex);
    if (ctxt->closed || ctxt->_uiContent == nullptr || ctxt->_sessionId <= 0) {
        return;
    }
    ctxt->closed = true;
    auto host = ctxt->hostContext.lock();
    auto content = host == nullptr ? nullptr : host->GetUIContent();
    if (content != nullptr && content == ctxt->_uiContent) {
        // This implementation posts CloseModalUIExtension to UI asynchronously.
        // Keep the lifetime lock until it has copied its native session/id task.
        content->CloseModalUIExtension(ctxt->_sessionId);
    }
}

void CalendarManagerNapi::QueueEditorResult(const std::shared_ptr<EditEventContext> &ctxt,
    bool failed, int32_t code, const std::string &message, int32_t eventId, bool closeModal)
{
    uint64_t generation;
    {
        std::lock_guard<std::mutex> lock(ctxt->mutex);
        if (ctxt->cancelled || ctxt->settled || ctxt->completionQueued) {
            return;
        }
        ctxt->completionQueued = true;
        generation = ctxt->generation;
    }
    napi_status status = napi_closing;
    auto environment = ctxt->environment;
    {
        // Cleanup is registered/removed only on JS. Its mutex excludes a sender
        // from using env while the cleanup hook invalidates the environment.
        std::lock_guard<std::mutex> envLock(environment->mutex);
        if (environment->alive) {
            status = napi_send_event(environment->env,
                [ctxt, generation, failed, code, message, eventId, closeModal] {
                    FinishEditor(ctxt, generation, failed, code, message, eventId, closeModal);
                }, napi_eprio_high);
        }
    }
    if (status != napi_ok) {
        {
            std::lock_guard<std::mutex> lock(ctxt->mutex);
            ctxt->cancelled = true;
            ++ctxt->generation;
            ctxt->completionQueued = false;
            ctxt->deferred = nullptr;
        }
        // No NAPI fallback on a UI callback when JS delivery is unavailable.
        LOG_ERROR("Calendar editor JS event delivery failed");
        CloseEditorSession(ctxt);
    }
}

void CalendarManagerNapi::FinishEditor(const std::shared_ptr<EditEventContext> &ctxt, uint64_t generation,
    bool failed, int32_t code, const std::string &message, int32_t eventId, bool closeModal)
{
    auto environment = ctxt->environment;
    std::lock_guard<std::mutex> envLock(environment->mutex);
    if (!environment->alive) {
        return;
    }
    napi_env env = environment->env;
    napi_deferred deferred;
    void *cleanup;
    {
        std::lock_guard<std::mutex> lock(ctxt->mutex);
        if (ctxt->cancelled || ctxt->settled || ctxt->generation != generation) {
            return;
        }
        ctxt->settled = true;
        ctxt->completionQueued = false;
        deferred = ctxt->deferred;
        ctxt->deferred = nullptr;
        cleanup = ctxt->cleanup;
    }
    napi_handle_scope scope = nullptr;
    if (napi_open_handle_scope(env, &scope) == napi_ok) {
        napi_value result = nullptr;
        if (failed) {
            napi_value text = nullptr;
            napi_value errorCode = nullptr;
            napi_create_string_utf8(env, message.c_str(), NAPI_AUTO_LENGTH, &text);
            napi_create_error(env, nullptr, text, &result);
            napi_create_int32(env, code, &errorCode);
            napi_set_named_property(env, result, "code", errorCode);
            napi_reject_deferred(env, deferred, result);
        } else {
            napi_create_int32(env, eventId, &result);
            napi_resolve_deferred(env, deferred, result);
        }
        napi_close_handle_scope(env, scope);
    } else {
        LOG_ERROR("Calendar editor cannot open JS handle scope");
    }
    if (cleanup != nullptr && napi_remove_env_cleanup_hook(env, CleanupEditorEnvironment, cleanup) == napi_ok) {
        {
            std::lock_guard<std::mutex> lock(ctxt->mutex);
            ctxt->cleanup = nullptr;
        }
        delete static_cast<EditorCleanup *>(cleanup);
    }
    if (closeModal) {
        CloseEditorSession(ctxt);
    }
}

napi_value CalendarManagerNapi::LaunchEditorPage(napi_env env, std::shared_ptr<EditEventContext> ctxt)
{
    napi_value promise = nullptr;
    if (napi_create_promise(env, &ctxt->deferred, &promise) != napi_ok) {
        napi_throw_error(env, nullptr, "Cannot create calendar editor promise");
        return nullptr;
    }
    ctxt->environment = std::make_shared<EditorEnvironment>();
    ctxt->environment->env = env;
    auto cleanup = new EditorCleanup { ctxt->environment, ctxt };
    if (napi_add_env_cleanup_hook(env, CleanupEditorEnvironment, cleanup) != napi_ok) {
        delete cleanup;
        FinishEditor(ctxt, ctxt->generation, true, INTERNAL_ERROR, "Cannot watch calendar editor environment",
            INVALID_EVENT_ID, false);
        return promise;
    }
    ctxt->cleanup = cleanup;
    if (ctxt->error.code != NO_ERROR || ctxt->status != napi_ok || ctxt->_uiContent == nullptr) {
        int32_t code = ctxt->error.code == NO_ERROR ? INTERNAL_ERROR : ctxt->error.code;
        FinishEditor(ctxt, ctxt->generation, true, code, "Calendar editor context is unavailable",
            INVALID_EVENT_ID, false);
        return promise;
    }
    AAFwk::Want want;
    want.SetElementName("com.ohos.calendardata", "EditorUIExtensionAbility");
    want.SetParam("ability.want.params.uiExtensionType", std::string("sys/commonUI"));
    want.SetParam("event", ctxt->event);
    // Caller identity is display-only input and is never used to authorize a write.
    Ace::ModalUIExtensionCallbacks callbacks;
    callbacks = {
        .onRelease = [ctxt](int32_t code) {
            QueueEditorResult(ctxt, code != 0, INTERNAL_ERROR, "Calendar editor was released", INVALID_EVENT_ID, true);
        },
        .onResult = [ctxt](int32_t code, const AAFwk::Want &wantRes) {
            int32_t eventId = wantRes.GetIntParam("eventId", INVALID_EVENT_ID);
            bool failed = code != 0 || eventId == 0;
            int32_t errorCode = wantRes.GetIntParam("errorCode", code > 0 ? code : INTERNAL_ERROR);
            QueueEditorResult(ctxt, failed, errorCode, "Calendar editor operation failed",
                eventId > 0 ? eventId : INVALID_EVENT_ID, true);
        },
        .onReceive = [](const AAFwk::WantParams &) {},
        .onError = [ctxt](int32_t code, const std::string &, const std::string &msg) {
            QueueEditorResult(ctxt, true, code > 0 ? code : INTERNAL_ERROR, msg, INVALID_EVENT_ID, true);
        },
        .onRemoteReady = [](const std::shared_ptr<Ace::ModalUIExtensionProxy> &) {},
        .onDestroy = [ctxt] {
            {
                // Invalidate native lifetime immediately on UI, before posting
                // cancellation. A queued result must never close a dead host.
                std::lock_guard<std::mutex> lock(ctxt->mutex);
                ctxt->closed = true;
                ctxt->_uiContent = nullptr;
                ++ctxt->generation;
                ctxt->completionQueued = false;
            }
            QueueEditorResult(ctxt, false, 0, "", INVALID_EVENT_ID, false);
        },
    };
    Ace::ModalUIExtensionConfig config;
    config = { .isProhibitBack = false };
    int32_t sessionId = ctxt->_uiContent->CreateModalUIExtension(want, callbacks, config);
    uint64_t generation;
    bool cancelSession;
    {
        std::lock_guard<std::mutex> lock(ctxt->mutex);
        ctxt->_sessionId = sessionId;
        generation = ctxt->generation;
        cancelSession = ctxt->cancelled || ctxt->settled;
    }
    if (sessionId <= 0) {
        FinishEditor(ctxt, generation, true, INTERNAL_ERROR, "Cannot create calendar editor session",
            INVALID_EVENT_ID, false);
    } else if (cancelSession) {
        // A send failure during synchronous creation had no session id yet.
        CloseEditorSession(ctxt);
    }
    return promise;
}

napi_value CalendarManagerNapi::New(napi_env env, napi_callback_info info)
{
    auto ctxt = std::make_shared<ContextBase>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 1, PARAMETER_INVALID, "invalid arguments!");
        CalendarEnvNapi::GetInstance().Init(env, argv[0]);
    };
    ctxt->GetCbInfoSync(env, info, input);
    NAPI_ASSERT(env, ctxt->status == napi_ok, "invalid arguments!");

    auto calendarManager = new (std::nothrow) CalendarManagerNapi();
    NAPI_ASSERT(env, calendarManager != nullptr, "no memory for calendarManager");
    auto finalize = [](napi_env env, void *data, void *hint) {
        CalendarManagerNapi *objectInfo = static_cast<CalendarManagerNapi *>(data);
        if (objectInfo != nullptr) {
            delete objectInfo;
            objectInfo = nullptr;
        }
    };
    if (napi_wrap(env, ctxt->self, calendarManager, finalize, nullptr, nullptr) != napi_ok) {
        finalize(env, calendarManager, nullptr);
        return nullptr;
    }
    return ctxt->self;
}

napi_value CalendarManagerNapi::Init(napi_env env, napi_value exports)
{
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_FUNCTION("createCalendar", CreateCalendar),
        DECLARE_NAPI_FUNCTION("deleteCalendar", DeleteCalendar),
        DECLARE_NAPI_FUNCTION("getCalendar", GetCalendar),
        DECLARE_NAPI_FUNCTION("getAllCalendars", GetAllCalendars),
        DECLARE_NAPI_FUNCTION("editEvent", EditEvent),
    };
    napi_value cons = nullptr;
    NAPI_CALL(env,
        napi_define_class(env,
            CALENDAR_MANAGER_CLASS_NAME.c_str(),
            NAPI_AUTO_LENGTH,
            New,
            nullptr,
            sizeof(properties) / sizeof(*properties),
            properties,
            &cons));
    NAPI_CALL(env, napi_create_reference(env, cons, INITIAL_REFCOUNT, &g_constructorRef));
    NAPI_CALL(env, napi_set_named_property(env, exports, CALENDAR_MANAGER_CLASS_NAME.c_str(), cons));

    napi_property_descriptor export_properties[] = {
        DECLARE_NAPI_FUNCTION("getCalendarManager", GetCalendarManager),
    };
    NAPI_CALL(env, napi_define_properties(env, exports, sizeof(export_properties) / sizeof(export_properties[0]),
        export_properties));
    return exports;
}
}
