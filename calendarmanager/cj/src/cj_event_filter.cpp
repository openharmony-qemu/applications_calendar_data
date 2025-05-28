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
#include "native/ffi_remote_data.h"
#include "ipc_skeleton.h"
#include "calendar_log.h"

using namespace OHOS;
using namespace OHOS::AbilityRuntime;
using namespace OHOS::CalendarApi;
using namespace OHOS::FFI;
using namespace OHOS::DataShare;

namespace OHOS {
namespace CalendarApi {
CJEventFilter::CJEventFilter(): FFIData() {}

int64_t CJEventFilter::FilterById(CArrI64 idsCArr, int32_t* errcode)
{
    std::vector<int> ids;
    for (int64_t i = 0; i < idsCArr.size; i++) {
        ids.push_back(static_cast<int>(idsCArr.head[i]));
    }
    CJEventFilter *cjEventFilter = FFI::FFIData::Create<CJEventFilter>();
    if (cjEventFilter == nullptr) {
        LOG_ERROR("cjEventFilter is nullptr");
        *errcode = -1;
    }

    cjEventFilter->eventFilter_ = OHOS::CalendarApi::Native::FilterById(ids);
    if (cjEventFilter->eventFilter_ == nullptr) {
        LOG_ERROR("cjEventFilter->eventFilter_ is nullptr");
        *errcode = -1;
    }
    return cjEventFilter->GetID();
}

int64_t CJEventFilter::FilterByTime(int64_t startTime, int64_t end, int32_t* errcode)
{
    CJEventFilter *cjEventFilter = FFI::FFIData::Create<CJEventFilter>();
    if (cjEventFilter == nullptr) {
        LOG_ERROR("cjEventFilter is nullptr");
        *errcode = -1;
    }
    cjEventFilter->eventFilter_ = OHOS::CalendarApi::Native::FilterByTime(startTime, end);
    if (cjEventFilter->eventFilter_ == nullptr) {
        LOG_ERROR("cjEventFilter->eventFilter_ is nullptr");
        *errcode = -1;
    }
    return cjEventFilter->GetID();
}

int64_t CJEventFilter::FilterByTitle(char* title, int32_t* errcode)
{
    CJEventFilter *cjEventFilter = FFI::FFIData::Create<CJEventFilter>();
    std::string eventName = std::to_string(title);
    if (cjEventFilter == nullptr) {
        LOG_ERROR("cjEventFilter is nullptr");
        *errcode = -1;
    }
    cjEventFilter->eventFilter_ = OHOS::CalendarApi::Native::FilterByTitle(eventName);
    if (cjEventFilter->eventFilter_ == nullptr) {
        LOG_ERROR("cjEventFilter->eventFilter_ is nullptr");
        *errcode = -1;
    }
    return cjEventFilter->GetID();
}

}
}