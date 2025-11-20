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
#include <unordered_map>
#include <vector>
#include <atomic>
#include <cstdint>
#include <mutex>
#include <thread>
#include <condition_variable>
#include <limits>

namespace OHOS::CalendarApi {

struct ApiStat {
    std::atomic<int> total_calls{0};
    std::atomic<int64_t> batch_start_time{0};
    // New metrics for reporting
    std::atomic<int> success_calls{0};
    std::atomic<int64_t> total_cost_ms{0};
    std::atomic<int64_t> max_cost_ms{0};
    std::atomic<int64_t> min_cost_ms{std::numeric_limits<int64_t>::max()};

    void reset()
    {
        total_calls = 0;
        batch_start_time = 0;
        success_calls = 0;
        total_cost_ms = 0;
        max_cost_ms = 0;
        min_cost_ms = std::numeric_limits<int64_t>::max();
    }
};

struct ReportData {
    std::string api_name;
    int total_calls;
    int64_t batch_start_time;
    // New reported fields
    int64_t success_times;
    int64_t max_cost_time;
    int64_t min_cost_time;
    int64_t total_cost_time;
};

class ReportHiEventManager {
public:
    static ReportHiEventManager& getInstance();

    ReportHiEventManager(const ReportHiEventManager&) = delete;
    ReportHiEventManager& operator=(const ReportHiEventManager&) = delete;

    ~ReportHiEventManager();

    int64_t AddProcessor();
    void SchedulerUpload(const ReportData& data);
    void WriteCallStatusEvent(const ReportData& data);

    int64_t onApiCallEnd(const std::string& api_name, bool success, int64_t cost_ms);

    void stopReporting();
    int64_t getCurrentTime();

private:
    ReportHiEventManager();

    ApiStat& getOrCreateStat(const std::string& api_name);
    void checkCallThreshold();
    void performReporting();
    void reportingThreadFunc();

    void notifyReportingThread();

    bool shouldAutoStop() const;
    void ensureReportingRunning();

    mutable std::mutex stats_mutex_;
    std::unordered_map<std::string, ApiStat> api_stats_;

    std::condition_variable report_thread_cv_;
    mutable std::mutex report_thread_cv_mutex_;
    bool need_immediate_report_{false};
    std::atomic<bool> report_thread_waiting_{false};
    mutable std::mutex start_mutex_;

    std::atomic<bool> reporting_{false};
    std::atomic<bool> stop_reporting_{false};
    std::atomic<bool> reporting_started_{false};
    std::thread report_thread_;

    int report_interval_seconds_{60};
    int call_threshold_{300};

    std::atomic<int> total_api_calls_{0};
    std::atomic<int64_t> last_api_call_time_{0};
    static std::atomic<int64_t> processorId;
};
} // namespace OHOS::CalendarApi
#endif //OHOS_CALENDAR_REPORT_HIEVENT_MANAGER_H