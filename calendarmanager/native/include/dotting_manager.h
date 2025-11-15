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

#ifndef OHOS_CALENDAR_DOTTING_MANAGER_H
#define OHOS_CALENDAR_DOTTING_MANAGER_H
#include <string>
#include <unordered_map>
#include <vector>
#include <atomic>
#include <mutex>
#include <thread>

namespace OHOS::CalendarApi {

struct ApiStat {
    std::atomic<int> total_calls{0};
    std::atomic<int> success_calls{0};
    std::atomic<int64_t> batch_start_time{0};
    std::vector<std::string> error_code_types;
    std::vector<int> error_code_num;
    mutable std::mutex error_mutex;

    void reset() {
        total_calls = 0;
        success_calls = 0;
        {
            std::lock_guard<std::mutex> lock(error_mutex);
            error_code_types.clear();
            error_code_num.clear();
        }
    }

    void addErrorCode(const std::string& error_code) {
        std::lock_guard<std::mutex> lock(error_mutex);

        auto it = std::find(error_code_types.begin(), error_code_types.end(), error_code);
        if (it != error_code_types.end()) {
            size_t index = std::distance(error_code_types.begin(), it);
            error_code_num[index]++;
        } else {
            error_code_types.push_back(error_code);
            error_code_num.push_back(1);
        }
    }
};

struct ReportData {
    std::string api_name;
    int total_calls;
    int success_calls;
    int64_t batch_start_time;
    std::vector<std::string> error_code_types;
    std::vector<int> error_code_num;
};

class DottingManager {
public:
    static DottingManager& getInstance();

    DottingManager(const DottingManager&) = delete;
    DottingManager& operator=(const DottingManager&) = delete;

    ~DottingManager();

    int64_t AddProcessor();
    void SchedulerUpload(const ReportData& data);
    void WriteCallStatusEvent(const ReportData& data);

    int64_t onApiCallStart(const std::string& api_name);
    void onApiCallSuccess(const std::string& api_name);
    void onApiCallError(const std::string& api_name, const std::string& error_code);

    void startReporting(int interval_seconds = 60, int call_threshold = 300);
    void stopReporting();
    int getTotalApiCalls() const { return total_api_calls_.load(); }

    bool isReporting() const { return reporting_.load(); }
    bool hasApiBeenCalled() const { return has_api_been_called_.load(); }

private:
    DottingManager();

    ApiStat& getOrCreateStat(const std::string& api_name);
    void checkCallThreshold();
    void performReporting();
    void reportingThreadFunc();

    void startReportingInternal();

    mutable std::mutex stats_mutex_;
    std::unordered_map<std::string, ApiStat> api_stats_;

    std::atomic<bool> reporting_{false};
    std::atomic<bool> stop_reporting_{false};
    std::atomic<bool> has_api_been_called_{false};
    std::atomic<bool> reporting_started_{false};
    std::thread report_thread_;

    int report_interval_seconds_{60};
    int call_threshold_{300};

    std::atomic<int> total_api_calls_{0};
    static int64_t processorId;
};
} // namespace OHOS::CalendarApi
#endif //OHOS_CALENDAR_DOTTING_MANAGER_H