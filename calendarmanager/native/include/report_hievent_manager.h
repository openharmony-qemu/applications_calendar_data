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

#ifndef OHOS_CALENDAR_REPORT_HIEVENT_MANAGER_H
#define OHOS_CALENDAR_REPORT_HIEVENT_MANAGER_H
#include <string>
#include <cstdint>

namespace OHOS::CalendarApi {

class ReportHiEventManager {
public:
    static ReportHiEventManager& GetInstance();

    ReportHiEventManager(const ReportHiEventManager&) = delete;
    ReportHiEventManager& operator=(const ReportHiEventManager&) = delete;

    ~ReportHiEventManager();

    // Public API: Record the end of an API call
    // Parameters: apiName - name of the API, success - whether the call succeeded, 
    //           beginTime - start time in milliseconds
    // Returns: batch start time for the API
    int64_t OnApiCallEnd(const std::string& apiName, bool success, int64_t beginTime);

    // Public API: Get current time in milliseconds
    int64_t GetCurrentTime();

    // Gracefully stop reporting
    void StopReporting();

private:
    ReportHiEventManager();
};

} // namespace OHOS::CalendarApi
#endif //OHOS_CALENDAR_REPORT_HIEVENT_MANAGER_H