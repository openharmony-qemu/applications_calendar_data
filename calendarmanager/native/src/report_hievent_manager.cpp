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
#include "report_hievent_manager.h"
#include "calendar_log.h"
#include <mutex>
#include <thread>
#include <condition_variable>
#include <chrono>
#include <queue>
#include <unordered_map>
#include <climits>
#ifdef DEVICE_USAGE_HIAPPEVENT_ENABLE
#include "app_event.h"
#include "app_event_processor_mgr.h"

namespace {
    constexpr int IDLE_TIME_OUT_MS = 180000;
    constexpr int REPORT_INTERVAL_SECONDS = 60;
    constexpr int CALL_THRESHOLD = 300;
    constexpr int64_t REPORT_NOT_SUPPORT_CODE = -200;
    constexpr size_t MAX_QUEUE_SIZE = 2000;
}
#endif

namespace OHOS::CalendarApi::Native {

struct ApiCallRecord {
    std::string apiName;
    bool success;
    int64_t costMs;
    int64_t timestamp;
};

struct ApiAggregatedStat {
    std::string apiName;
    int totalCalls = 0;
    int successCalls = 0;
    int64_t totalCostMs = 0;
    int64_t maxCostMs = 0;
    int64_t minCostMs = INT64_MAX;
    int64_t batchStartTime = 0;

    void Aggregate(const ApiCallRecord& record)
    {
        totalCalls++;
        if (record.success) {
            successCalls++;
        }
        totalCostMs += record.costMs;
        maxCostMs = std::max(maxCostMs, record.costMs);
        minCostMs = std::min(minCostMs, record.costMs);

        if (batchStartTime == 0) {
            batchStartTime = record.timestamp;
        }
    }
};

#ifdef DEVICE_USAGE_HIAPPEVENT_ENABLE
class ReportHiEventManager::ReportHiEventManagerImpl {
public:
    ReportHiEventManagerImpl() = default;
    ~ReportHiEventManagerImpl() { StopReporting(); }

    int64_t OnApiCallEnd(const std::string& apiName, bool success, int64_t beginTime)
    {
        // api调用结束后记录是否成功和时延写入队列，满足条件后聚合上报
        auto endTime = GetCurrentTime();
        auto costMs = endTime - beginTime;

        {
            std::lock_guard<std::mutex> lock(m_queueMutex);
            if (m_callQueue.size() >= MAX_QUEUE_SIZE) {
                return endTime;
            }
            m_callQueue.push({apiName, success, costMs, endTime});
            m_lastApiCallTime.store(endTime);
        }

        EnsureReportingRunning();
        CheckReportConditions();
        return endTime;
    }

    int64_t GetCurrentTime()
    {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
    }

    void StopReporting()
    {
        {
            std::lock_guard<std::mutex> lock(m_threadControlMutex);
            if (!m_isWorkThreadRunning.load()) {
                return;
            }
            m_stopReporting = true;
        }

        m_reportCv.notify_one();

        if (m_reportThread.joinable()) {
            m_reportThread.join();
        }

        m_isWorkThreadRunning = false;
        LOG_INFO("ReportHiEventManager reporting stopped");
    }

private:

    void EnsureReportingRunning()
    {
        if (m_isWorkThreadRunning.load()) {
            return;
        }
        std::unique_lock<std::mutex> lock(m_threadControlMutex);
        if (m_isWorkThreadRunning.load()) {
            return;
        }

        if (m_reportThread.joinable()) {
            m_stopReporting.store(true);
            m_reportCv.notify_one();
            lock.unlock();
            m_reportThread.join();
            lock.lock();
        }

        //start new thread
        m_stopReporting.store(false);
        m_isWorkThreadRunning.store(true);
        m_reportThread = std::thread([this]() { ReportingThreadFunc(); });
    }

    void CheckReportConditions()
    {
        std::lock_guard<std::mutex> lock(m_queueMutex);
        if (static_cast<int>(m_callQueue.size()) >= CALL_THRESHOLD) {
            m_thresholdReached.store(true);
            m_reportCv.notify_one();
        }
    }

    void ReportingThreadFunc()
    {
        LOG_INFO("Reporting thread started");
        auto lastReportTime = std::chrono::steady_clock::now();
        while (!m_stopReporting) {
            {
                std::unique_lock<std::mutex> lock(m_threadControlMutex);
                auto sleepDuration = std::chrono::seconds(1);
                m_reportCv.wait_for(lock, sleepDuration, [this]() {
                    return m_stopReporting || m_thresholdReached.load();
                });
            }

            if (ShouldAutoStop()) {
                LOG_INFO("Reporting thread idle timeout, stopping");
                break;
            }

            auto now = std::chrono::steady_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(
                now - lastReportTime).count();
            if (elapsed >= REPORT_INTERVAL_SECONDS || m_stopReporting || m_thresholdReached.exchange(false)) {
                PerformReporting();
                lastReportTime = now;
            }
        }

        // Final report before exit
        if (!m_stopReporting.load()) {
            PerformReporting();
        }

        m_isWorkThreadRunning = false;
        LOG_INFO("Reporting thread exiting");
    }

    bool ShouldAutoStop()
    {
        auto now = GetCurrentTime();
        auto idleMs = now - m_lastApiCallTime;
        return idleMs > IDLE_TIME_OUT_MS;
    }

    void PerformReporting()
    {
        std::queue<ApiCallRecord> recordsSnapshot;
        
        {
            std::lock_guard<std::mutex> lock(m_queueMutex);
            if (m_callQueue.empty()) {
                return;
            }
            std::swap(recordsSnapshot, m_callQueue);
        }

        std::unordered_map<std::string, ApiAggregatedStat> aggregated;
        
        while (!recordsSnapshot.empty()) {
            const auto& record = recordsSnapshot.front();
            aggregated[record.apiName].Aggregate(record);
            if (aggregated[record.apiName].apiName.empty()) {
                aggregated[record.apiName].apiName = record.apiName;
            }
            recordsSnapshot.pop();
        }

        for (auto& [apiName, stat] : aggregated) {
            WriteCallStatusEvent(stat);
        }

        LOG_INFO("PerformReporting completed, reported %{public}zu APIs", aggregated.size());
    }

    void WriteCallStatusEvent(const ApiAggregatedStat& stat)
    {
        if (m_processorId == -1) {
            m_processorId = AddProcessor();
        }

        if (m_processorId == REPORT_NOT_SUPPORT_CODE) {
            LOG_ERROR("Reporting Error, code -200.");
            return;
        }

        HiviewDFX::HiAppEvent::Event event("api_diagnostic", "api_called_stat", OHOS::HiviewDFX::HiAppEvent::BEHAVIOR);
        event.AddParam("api_name", stat.apiName);
        event.AddParam("sdk_name", std::string("CalendarKit"));
        event.AddParam("begin_time", stat.batchStartTime);
        event.AddParam("call_times", stat.totalCalls);
        event.AddParam("success_times", stat.successCalls);
        event.AddParam("max_cost_time", stat.maxCostMs > 0 ? stat.maxCostMs : 0);
        event.AddParam("min_cost_time", stat.minCostMs < INT64_MAX ? stat.minCostMs : 0);
        event.AddParam("total_cost_time", stat.totalCostMs);
        
        HiviewDFX::HiAppEvent::Write(event);
    }

    int64_t AddProcessor()
    {
        HiviewDFX::HiAppEvent::ReportConfig config;
        config.name = "ha_app_event";
        config.appId = "com_huawei_hmos_sdk_ocg";
        config.routeInfo = "AUTO";

        HiviewDFX::HiAppEvent::EventConfig event1;
        event1.domain = "api_diagnostic";
        event1.name = "api_exec_end";
        event1.isRealTime = false;
        config.eventConfigs.push_back(event1);
        
        HiviewDFX::HiAppEvent::EventConfig event2;
        event2.domain = "api_diagnostic";
        event2.name = "api_called_stat";
        event2.isRealTime = true;
        config.eventConfigs.push_back(event2);

        HiviewDFX::HiAppEvent::EventConfig event3;
        event3.domain = "api_diagnostic";
        event3.name = "api_called_stat_cnt";
        event3.isRealTime = true;
        config.eventConfigs.push_back(event3);

        return HiviewDFX::HiAppEvent::AppEventProcessorMgr::AddProcessor(config);
    }

    mutable std::mutex m_queueMutex;
    mutable std::mutex m_threadControlMutex;
    std::condition_variable m_reportCv;
    std::thread m_reportThread;

    std::queue<ApiCallRecord> m_callQueue;

    std::atomic<bool> m_isWorkThreadRunning{false};
    std::atomic<bool> m_stopReporting{false};
    std::atomic<bool> m_thresholdReached{false};
    std::atomic<int64_t> m_lastApiCallTime{0};

    int64_t m_processorId{-1};
};

#else
class ReportHiEventManager::ReportHiEventManagerImpl {
public:
    ReportHiEventManagerImpl()
    {
        LOG_WARN("Device usage hiappevent is not enabled, reporting disabled.");
    }
    ~ReportHiEventManagerImpl() = default;

    int64_t OnApiCallEnd(const std::string& apiName, bool success, int64_t beginTime)
    {
        return beginTime;
    }

    int64_t GetCurrentTime()
    {
        return 0;
    }

    void StopReporting()
    {
    }
#endif

ReportHiEventManager& ReportHiEventManager::GetInstance()
{
    static ReportHiEventManager instance;
    return instance;
}

ReportHiEventManager::ReportHiEventManager()
    : m_impl(std::make_unique<ReportHiEventManagerImpl>())
{
}

ReportHiEventManager::~ReportHiEventManager() = default;

int64_t ReportHiEventManager::OnApiCallEnd(const std::string& apiName, bool success, int64_t beginTime)
{
    return m_impl->OnApiCallEnd(apiName, success, beginTime);
}

int64_t ReportHiEventManager::GetCurrentTime()
{
    return m_impl->GetCurrentTime();
}

void ReportHiEventManager::StopReporting()
{
    m_impl->StopReporting();
}

} // namespace OHOS::CalendarApi::Native