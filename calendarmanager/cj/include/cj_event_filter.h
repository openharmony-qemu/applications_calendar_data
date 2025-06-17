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
#ifndef CJ_EVENT_FILTER_H
#define CJ_EVENT_FILTER_H

#include <cstdint>
#include <vector>
#include "cj_common_ffi.h"
#include "ffi_remote_data.h"
#include "calendar_manager_ffi.h"
#include "cj_native_util.h"
#include "cj_native_calendar.h"

namespace OHOS {
namespace CalendarApi {
class CJEventFilter : public OHOS::FFI::FFIData {
    DECL_TYPE(CJEventFilter, OHOS::FFI::FFIData)
public:
    CJEventFilter();
    ~CJEventFilter() override = default;
    static int64_t FilterById(CArrI64 idsCArr, int32_t* errcode);
    static int64_t FilterByTime(int64_t startTime, int64_t end, int32_t* errcode);
    static int64_t FilterByTitle(char* title, int32_t* errcode);
    std::shared_ptr<Native::EventFilter> eventFilter_ = nullptr;
};

}
}

#endif // CJ_CALENDAR_MANAGER_H