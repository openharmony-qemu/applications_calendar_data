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
#include "calendar_log.h"
#include "napi_util.h"
#include "napi_queue.h"
#include "calendar_napi.h"
#include "native_calendar_manager.h"

#include "abs_shared_result_set.h"
#include "data_ability_helper.h"
#include "data_ability_predicates.h"
#include "values_bucket.h"

using namespace OHOS::AppExecFwk;
using namespace OHOS::DataShare;

namespace OHOS::CalendarApi {
napi_value CalendarManagerNapi::CreateCalendar(napi_env env, napi_callback_info info)
{
    struct CreateCalendarContext : public ContextBase {
        CalendarAccount account;
        CalendarNapi *calendar;
        napi_ref ref = nullptr;
    };
    auto ctxt = std::make_shared<CreateCalendarContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        // required 1 arguments :: <CalendarAccount>
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 1, "invalid arguments!");
        NapiUtil::GetValue(env, argv[0], ctxt->account);
        CHECK_STATUS_RETURN_VOID(ctxt, "invalid arg[0], i.e. invalid keys!");
        ctxt->ref = NapiUtil::NewWithRef(env, argc, argv, reinterpret_cast<void**>(&ctxt->calendar),
            CalendarNapi::Constructor(env));
    };
    ctxt->GetCbInfo(env, info, input);

    auto execute = [ctxt]() {
        auto nativteCalendar = Native::CalendarManager::GetInstance().CreateCalendar(ctxt->account);
        ctxt->status = (nativteCalendar != nullptr) ? napi_ok : napi_generic_failure;
        CHECK_STATUS_RETURN_VOID(ctxt, "GetCalendar failed!");
        ctxt->calendar->SetNative(nativteCalendar);
    };
    auto output = [env, ctxt](napi_value& result) {
        ctxt->status = napi_get_reference_value(env, ctxt->ref, &result);
        CHECK_STATUS_RETURN_VOID(ctxt, "output get ref value failed");
        ctxt->status = napi_delete_reference(env, ctxt->ref);
        CHECK_STATUS_RETURN_VOID(ctxt, "output del ref failed");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

napi_value CalendarManagerNapi::DeleteCalendar(napi_env env, napi_callback_info info)
{
    struct DelCalendarContext : public ContextBase {
        CalendarAccount account;
        CalendarNapi *calendar;
        bool delResult = false;
    };
    auto ctxt = std::make_shared<DelCalendarContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        // required 1 arguments :: <Calendar>
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 1, "invalid arguments!");
        napi_valuetype type = napi_undefined;
        napi_typeof(env, argv[0], &type);
        CHECK_ARGS_RETURN_VOID(ctxt, type == napi_object, "type error!");
        ctxt->status = CalendarNapi::ToJson(env, argv[0], ctxt->calendar);
        CHECK_STATUS_RETURN_VOID(ctxt, "invalid arg[0], i.e. invalid keys!");
    };
    ctxt->GetCbInfo(env, info, input);

    auto execute = [ctxt]() {
        CHECK_RETURN_VOID(ctxt->calendar, "calendar is nullptr");
        auto nativeCalendar = ctxt->calendar->GetNative();
        CHECK_RETURN_VOID(nativeCalendar, "calendar is nullptr");
        ctxt->delResult = Native::CalendarManager::GetInstance()
            .DeleteCalendar(*(nativeCalendar.get()));
        CHECK_RETURN_VOID(ctxt->delResult, "DeleteCalendar failed!");
    };
    auto output = [env, ctxt](napi_value& result) {
        NapiUtil::SetValue(env, ctxt->delResult, result);
        CHECK_STATUS_RETURN_VOID(ctxt, "output del ref failed");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

struct GetCalendarContext : public ContextBase {
    std::optional<CalendarAccount> account;
    CalendarNapi *calendar = nullptr;
    napi_ref ref = nullptr;

    void GetCbInfo(napi_env env, napi_callback_info info)
    {
        auto input = [env, this](size_t argc, napi_value* argv) {
            // required at least 1 arguments :: <CalendarAccount>
            CHECK_ARGS_RETURN_VOID(this, argc <= 1, "invalid arguments!");
            if (argc == 0) {
                this->account = std::nullopt;
            } else {
                CalendarAccount tmpAccount;
                NapiUtil::GetValue(env, argv[0], tmpAccount);
                this->account = tmpAccount;
            }
            CHECK_STATUS_RETURN_VOID(this, "invalid arg[0], i.e. invalid keys!");
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
        auto nativteCalendar = Native::CalendarManager::GetInstance().GetCalendar(ctxt->account);
        ctxt->status = (nativteCalendar != nullptr) ? napi_ok : napi_generic_failure;
        CHECK_STATUS_RETURN_VOID(ctxt, "GetCalendar failed!");
        ctxt->calendar->SetNative(nativteCalendar);
    };
    auto output = [env, ctxt](napi_value& result) {
        ctxt->status = napi_get_reference_value(env, ctxt->ref, &result);
        CHECK_STATUS_RETURN_VOID(ctxt, "output get ref value failed");
        ctxt->status = napi_delete_reference(env, ctxt->ref);
        CHECK_STATUS_RETURN_VOID(ctxt, "output del ref failed");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

napi_value CalendarManagerNapi::GetAllCalendars(napi_env env, napi_callback_info info)
{
    LOG_DEBUG("napi GetAllCalendars called");
    struct GetAllCalendarContext : public ContextBase {
        napi_callback_info info;
        std::vector<napi_ref> refs;
    };

    auto ctxt = std::make_shared<GetAllCalendarContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 0, "invalid arguments!");
        auto nativteCalendars = Native::CalendarManager::GetInstance().GetAllCalendars();
        for (auto &calendar : nativteCalendars) {
            CalendarNapi *calendarNapi = nullptr;
            auto ref = NapiUtil::NewWithRef(env, argc, argv, reinterpret_cast<void**>(&calendarNapi),
                CalendarNapi::Constructor(env));
            CHECK_RETURN_VOID(calendarNapi != nullptr, "new CalendarNapi failed!");
            calendarNapi->SetNative(calendar);
            ctxt->refs.emplace_back(ref);
        }
    };
    ctxt->GetCbInfo(env, info, input);

    auto execute = [env, ctxt]()->void {
    };

    auto output = [env, ctxt](napi_value& result) {
        ctxt->status = napi_create_array_with_length(env, ctxt->refs.size(), &result);
        CHECK_STATUS_RETURN_VOID(ctxt, "create array failed!");
        int index = 0;
        for (auto& ref : ctxt->refs) {
            napi_value value;
            ctxt->status = napi_get_reference_value(env, ref, &value);
            CHECK_STATUS_RETURN_VOID(ctxt, "get ref value failed!");
            ctxt->status = napi_set_element(env, result, index++, value);
            CHECK_STATUS_RETURN_VOID(ctxt, "napi_set_element failed!");
            ctxt->status = napi_delete_reference(env, ref);
            CHECK_STATUS_RETURN_VOID(ctxt, "napi_delete_reference failed!");
        }
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

napi_value CalendarManagerNapi::Init(napi_env env, napi_value exports)
{
    LOG_INFO("CalendarManagerNapi::Init");
    napi_property_descriptor descriptor[] = {
        DECLARE_NAPI_FUNCTION("createCalendar", CreateCalendar),
        DECLARE_NAPI_FUNCTION("deleteCalendar", DeleteCalendar),
        DECLARE_NAPI_FUNCTION("getCalendar", GetCalendar),
        DECLARE_NAPI_FUNCTION("getAllCalendars", GetAllCalendars),
    };
    NAPI_CALL(
        env, napi_define_properties(env, exports, sizeof(descriptor) / sizeof(napi_property_descriptor), descriptor));
    return exports;
}
}