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
#ifndef CALENDAR_MANAGER_NAPI_QUEUE_H
#define CALENDAR_MANAGER_NAPI_QUEUE_H
#include <functional>
#include <memory>
#include <string>

#include "calendar_log.h"
#include "napi/native_api.h"
#include "napi/native_common.h"
#include "napi/native_node_api.h"
#include "calendar_define.h"

namespace OHOS::CalendarApi {
constexpr size_t ARGC_MAX = 6;
using NapiCbInfoParser = std::function<void(size_t argc, napi_value* argv)>;
using NapiAsyncExecute = std::function<void(void)>;
using NapiAsyncComplete = std::function<void(napi_value&)>;

struct ContextBase {
    virtual ~ContextBase();
    void GetCbInfo(napi_env env, napi_callback_info info,
                   NapiCbInfoParser parse = NapiCbInfoParser(), bool sync = false);

    inline void GetCbInfoSync(napi_env env, napi_callback_info info, NapiCbInfoParser parse = NapiCbInfoParser())
    {
        GetCbInfo(env, info, parse, true);
    }

    napi_env env = nullptr;
    napi_value output = nullptr;
    napi_status status = napi_invalid_arg;
    Error error = {"", NO_ERROR};

    napi_value self = nullptr;
    void* native = nullptr;

private:
    napi_ref callbackRef = nullptr;
    napi_ref selfRef = nullptr;
    friend class NapiQueue;
};

inline void SetErrorValue(Error &error, ErrorCode code, std::string message)
{
    error.code = code;
    if (error.message.empty()) {
        error.message = message;
    }
    LOG_ERROR("failed: %{public}s", message.c_str());
}

/* check condition related to argc/argv, return and logging. */
#define CHECK_ARGS_RETURN_VOID(ctxt, condition, errCode, errMessage)              \
    do {                                                                    \
        if (!(condition)) {                                                 \
            (ctxt)->status = napi_invalid_arg;                              \
            SetErrorValue((ctxt)->error, errCode, errMessage);                  \
            LOG_ERROR("condition (" #condition ") failed: " errMessage);            \
            return;                                                         \
        }                                                                   \
    } while (0)

#define CHECK_STATUS_RETURN_VOID(ctxt, errCode, errMessage)                        \
    do {                                                               \
        if ((ctxt)->status != napi_ok) {                               \
            SetErrorValue((ctxt)->error, errCode, errMessage);                  \
            LOG_ERROR("(ctxt->status %{public}d) failed: " errMessage, (ctxt)->status);  \
            return;                                                    \
        }                                                              \
    } while (0)

#define CHECK_ERRCODE_RETURN_VOID(ctxt, errMessage)                        \
    do {                                                               \
            if ((ctxt)->error.code != NO_ERROR ) {                               \
                (ctxt)->error.message = std::string(errMessage);                             \
                LOG_ERROR("(ctxt->status %{public}d) failed: " errMessage, (ctxt)->status);  \
                return;                                                    \
            }                                                              \
    } while (0)

#define CHECK_RESULT_RETURN_VOID(ctxt, result, errMessage, retValue)                        \
    do {                                                               \
            if ((result).IsErr()) {                               \
                (ctxt)->error = (result).GetError();                 \
                SetErrorValue((ctxt)->error, (result).GetError().code, errMessage);           \
                (ctxt)->status = napi_generic_failure;                              \
                return;                                                    \
            }                                                                \
            (retValue) = (result).GetValue();                                                      \
    } while (0)

#define CHECK_ERRCODE_RETURN(error, message, retVal)                  \
    do {                                             \
            if ((error).code != NO_ERROR) {                \
                LOG_ERROR("failed: " message);  \
                return retVal;             \
            }                                        \
                                                     \
    } while (0)
    
/* check condition, return and logging if condition not true. */
#define CHECK_RETURN(condition, message, retVal)             \
    do {                                                     \
        if (!(condition)) {                                  \
            LOG_ERROR("condition (" #condition ") failed: " message); \
            return retVal;                                   \
        }                                                    \
    } while (0)

#define CHECK_RETURN_VOID(condition, message)                \
    do {                                                     \
        if (!(condition)) {                                  \
            LOG_ERROR("condition (" #condition ") failed: " message); \
            return;                                          \
        }                                                    \
    } while (0)

class NapiQueue {
public:
    static napi_value AsyncWork(napi_env env, std::shared_ptr<ContextBase> ctxt,
                                const std::string& name, NapiAsyncExecute execute = NapiAsyncExecute(),
                                NapiAsyncComplete complete = NapiAsyncComplete());

private:
    enum {
        RESULT_ERROR = 0,
        RESULT_DATA = 1,
        RESULT_ALL = 2
    };

    struct AsyncContext {
        napi_env env = nullptr;
        std::shared_ptr<ContextBase> ctx;
        NapiAsyncExecute execute = nullptr;
        NapiAsyncComplete complete = nullptr;
        napi_deferred deferred = nullptr;
        napi_async_work work = nullptr;
        ~AsyncContext()
        {
            execute = nullptr;
            complete = nullptr;
            ctx = nullptr;
            if (env != nullptr) {
                if (work != nullptr) {
                    napi_delete_async_work(env, work);
                }
            }
        }
    };
    static void GenerateOutput(AsyncContext &ctx, napi_value output);
};
} // namespace Calendar::CalendarApi
#endif