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

#ifndef CALENDAR_MANAGER_NAPI_H
#define CALENDAR_MANAGER_NAPI_H

#include <vector>
#include <mutex>

#include "napi/native_api.h"
#include "napi/native_common.h"
#include "napi/native_node_api.h"

#include "calendar_log.h"
#include "napi_util.h"
#include "napi_queue.h"
#include "calendar_napi.h"
#include "native_calendar_manager.h"
#include "napi_env.h"
#include "abs_shared_result_set.h"
#include "data_ability_helper.h"
#include "data_ability_predicates.h"
#include "values_bucket.h"

#include <ui_content.h>
#include "napi_base_context.h"
namespace OHOS::AbilityRuntime { class AbilityContext; }
namespace OHOS::CalendarApi {
class CalendarManagerNapi {
public:
    struct EditorEnvironment {
        std::mutex mutex;
        napi_env env = nullptr;
        bool alive = true;
    };
    struct EditEventContext : public ContextBase {
        std::mutex mutex;
        string event;
        string caller;
        int32_t _sessionId = 0;
        // Identity only: reacquire through the caller's live AbilityContext before closing.
        Ace::UIContent *_uiContent = nullptr;
        std::weak_ptr<AbilityRuntime::AbilityContext> hostContext;
        std::shared_ptr<EditorEnvironment> environment;
        napi_deferred deferred = nullptr;
        void *cleanup = nullptr;
        uint64_t generation = 0;
        bool completionQueued = false;
        bool cancelled = false;
        bool settled = false;
        bool closed = false;
    };
    struct EditorCleanup {
        std::shared_ptr<EditorEnvironment> environment;
        std::weak_ptr<EditEventContext> context;
    };

    static napi_value New(napi_env env, napi_callback_info info);
    static napi_value CreateCalendar(napi_env env, napi_callback_info info);
    static napi_value DeleteCalendar(napi_env env, napi_callback_info info);
    static napi_value GetCalendar(napi_env env, napi_callback_info info);
    static napi_value GetAllCalendars(napi_env env, napi_callback_info info);
    static napi_value EditEvent(napi_env env, napi_callback_info info);
    static napi_value Init(napi_env env, napi_value exports);
private:
    static void CleanupEditorEnvironment(void *data);
    static void CloseEditorSession(const std::shared_ptr<EditEventContext> &ctxt);
    static void QueueEditorResult(const std::shared_ptr<EditEventContext> &ctxt,
        bool failed, int32_t code, const std::string &message, int32_t eventId, bool closeModal);
    static void FinishEditor(const std::shared_ptr<EditEventContext> &ctxt, uint64_t generation,
        bool failed, int32_t code, const std::string &message, int32_t eventId, bool closeModal);
    static napi_value LaunchEditorPage(napi_env env, std::shared_ptr<EditEventContext> ctxt);
};

napi_value GetCalendarManager(napi_env env, napi_callback_info info);

}  // namespace Calendar::CalendarApi
#endif  //  CALENDAR_MANAGER_NAPI_H
