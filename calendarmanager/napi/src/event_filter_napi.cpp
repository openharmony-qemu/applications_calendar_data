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

#include "event_filter_napi.h"
#include "calendar_log.h"
#include "napi_util.h"
#include "napi_queue.h"

namespace OHOS::CalendarApi {

EventFilterNapi::EventFilterNapi()
{
}

napi_value EventFilterNapi::Constructor(napi_env env)
{
    napi_property_descriptor descriptor[] = {
        DECLARE_NAPI_STATIC_FUNCTION("filterById", EventFilterNapi::FilterById),
        DECLARE_NAPI_STATIC_FUNCTION("filterByTime", EventFilterNapi::FilterByTime),
        DECLARE_NAPI_STATIC_FUNCTION("filterByTitle", EventFilterNapi::FilterByTitle),
    };
    size_t count = sizeof(descriptor) / sizeof(descriptor[0]);
    return NapiUtil::DefineClass(env, "EventFilter", descriptor, count, EventFilterNapi::New);
}

napi_value EventFilterNapi::New(napi_env env, napi_callback_info info)
{
    LOG_DEBUG("EventFilterNapi new");
    auto ctxt = std::make_shared<ContextBase>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        CHECK_ARGS_RETURN_VOID(ctxt, argc >= 1, "invalid arguments!");
    };
    ctxt->GetCbInfoSync(env, info, input);
    NAPI_ASSERT(env, ctxt->status == napi_ok, "invalid arguments!");

    auto instance = new (std::nothrow) EventFilterNapi();
    NAPI_ASSERT(env, instance !=nullptr, "no memory for EventFilterNapi");

    auto finalize = [](napi_env env, void* data, void* hint) {
        LOG_DEBUG("EventFilterNapi finalize.");
        auto* instance = reinterpret_cast<EventFilterNapi*>(data);
        CHECK_RETURN_VOID(instance != nullptr, "finalize null!");
        delete instance;
    };
    if (napi_wrap(env, ctxt->self, instance, finalize, nullptr, nullptr) != napi_ok) {
        delete instance;
        GET_AND_THROW_LAST_ERROR(env);
        return nullptr;
    }
    return ctxt->self;
}

napi_status EventFilterNapi::ToJson(napi_env env, napi_value inner, EventFilterNapi*& out)
{
    LOG_DEBUG("EventFilterNapi::ToJson");
    return NapiUtil::Unwrap(env, inner, reinterpret_cast<void**>(&out), EventFilterNapi::Constructor(env));
}

void EventFilterNapi::SetNative(std::shared_ptr<Native::EventFilter>& eventFilter)
{
    eventFilter_ = eventFilter;
}

std::shared_ptr<Native::EventFilter>& EventFilterNapi::GetNative()
{
    return eventFilter_;
}

napi_value EventFilterNapi::FilterById(napi_env env, napi_callback_info info)
{
    LOG_INFO("FilterById");
    struct EventFilterByIdContext : public ContextBase {
        EventFilterNapi *filter;
        std::vector<int> ids;
        napi_ref ref = nullptr;
    };
    auto ctxt = std::make_shared<EventFilterByIdContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 1, "invalid arguments!");
        ctxt->status = NapiUtil::GetValue(env, argv[0], ctxt->ids);
        CHECK_STATUS_RETURN_VOID(ctxt, "invalid arg[0], i.e. invalid keys!");
        ctxt->ref = NapiUtil::NewWithRef(env, argc, argv, reinterpret_cast<void**>(&ctxt->filter),
            EventFilterNapi::Constructor(env));
    };
    ctxt->GetCbInfo(env, info, input);
    auto execute = [ctxt]() {
        CHECK_RETURN_VOID(ctxt->filter != nullptr, "filter is null!");
        auto nativeFilter = Native::FilterById(ctxt->ids);
        ctxt->status = (nativeFilter != nullptr) ? napi_ok : napi_generic_failure;
        CHECK_STATUS_RETURN_VOID(ctxt, "GetCalendar failed!");
        ctxt->filter->SetNative(nativeFilter);
    };
    auto output = [env, ctxt](napi_value& result) {
        ctxt->status = napi_get_reference_value(env, ctxt->ref, &result);
        CHECK_STATUS_RETURN_VOID(ctxt, "output get ref value failed");
        ctxt->status = napi_delete_reference(env, ctxt->ref);
        CHECK_STATUS_RETURN_VOID(ctxt, "output del ref failed");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}


napi_value EventFilterNapi::FilterByTime(napi_env env, napi_callback_info info)
{
    LOG_INFO("FilterByTime");
    struct EventFilterByTimeContext : public ContextBase {
        EventFilterNapi *filter;
        int64_t start;
        int64_t end;
        napi_ref ref = nullptr;
    };
    auto ctxt = std::make_shared<EventFilterByTimeContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        // required at 2 arguments :: <number start number end>
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 2, "invalid arguments!");
        ctxt->status = NapiUtil::GetValue(env, argv[0], ctxt->start);
        CHECK_STATUS_RETURN_VOID(ctxt, "invalid arg[0], i.e. invalid keys!");
        ctxt->status = NapiUtil::GetValue(env, argv[1], ctxt->end);
        CHECK_STATUS_RETURN_VOID(ctxt, "invalid arg[1], i.e. invalid keys!");
        ctxt->ref = NapiUtil::NewWithRef(env, argc, argv, reinterpret_cast<void**>(&ctxt->filter),
            EventFilterNapi::Constructor(env));
    };
    ctxt->GetCbInfo(env, info, input);
    auto execute = [ctxt]() {
        LOG_DEBUG("execute start:%{public}lu, end:%{public}lu", ctxt->start, ctxt->end);
        CHECK_RETURN_VOID(ctxt->filter != nullptr, "filter is null!");
        auto nativeFilter = Native::FilterByTime(ctxt->start, ctxt->end);
        LOG_DEBUG("nativeFilter %{public}p", nativeFilter.get());
        CHECK_RETURN_VOID(nativeFilter, "nativeFilter is null!");
        ctxt->status = (nativeFilter != nullptr) ? napi_ok : napi_generic_failure;
        CHECK_STATUS_RETURN_VOID(ctxt, "FilterByTime failed!");
        ctxt->filter->SetNative(nativeFilter);
        LOG_DEBUG("execute end");
    };
    auto output = [env, ctxt](napi_value& result) {
        LOG_DEBUG("output start");
        ctxt->status = napi_get_reference_value(env, ctxt->ref, &result);
        CHECK_STATUS_RETURN_VOID(ctxt, "output get ref value failed");
        ctxt->status = napi_delete_reference(env, ctxt->ref);
        CHECK_STATUS_RETURN_VOID(ctxt, "output del ref failed");
        LOG_DEBUG("output end");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

napi_value EventFilterNapi::FilterByTitle(napi_env env, napi_callback_info info)
{
    LOG_INFO("FilterByTitle");
    struct EventFilterByTitleContext : public ContextBase {
        EventFilterNapi *filter;
        string title;
        napi_ref ref = nullptr;
    };
    auto ctxt = std::make_shared<EventFilterByTitleContext>();
    auto input = [env, ctxt](size_t argc, napi_value* argv) {
        // required at 2 arguments :: <title string>
        CHECK_ARGS_RETURN_VOID(ctxt, argc == 1, "invalid arguments!");
        ctxt->status = NapiUtil::GetValue(env, argv[0], ctxt->title);
        CHECK_STATUS_RETURN_VOID(ctxt, "invalid arg[0], i.e. invalid keys!");
        ctxt->ref = NapiUtil::NewWithRef(env, argc, argv, reinterpret_cast<void**>(&ctxt->filter),
            EventFilterNapi::Constructor(env));
    };
    ctxt->GetCbInfo(env, info, input);
    auto execute = [ctxt]() {
        CHECK_RETURN_VOID(ctxt->filter != nullptr, "filter is null!");
        auto nativeFilter = Native::FilterByTitle(ctxt->title);
        ctxt->status = (nativeFilter != nullptr) ? napi_ok : napi_generic_failure;
        CHECK_STATUS_RETURN_VOID(ctxt, "GetCalendar failed!");
        ctxt->filter->SetNative(nativeFilter);
    };
    auto output = [env, ctxt](napi_value& result) {
        ctxt->status = napi_get_reference_value(env, ctxt->ref, &result);
        CHECK_STATUS_RETURN_VOID(ctxt, "output get ref value failed");
        ctxt->status = napi_delete_reference(env, ctxt->ref);
        CHECK_STATUS_RETURN_VOID(ctxt, "output del ref failed");
    };
    return NapiQueue::AsyncWork(env, ctxt, std::string(__FUNCTION__), execute, output);
}

napi_value EventFilterNapi::Init(napi_env env, napi_value exports)
{
    napi_set_named_property(env, exports, "EventFilter", EventFilterNapi::Constructor(env));
    return exports;
}

}