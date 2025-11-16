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
#include "app_event.h"
#include "app_event_processor_mgr.h"
#include "report_hievent_manager.h"
#include "calendar_log.h"
#include <chrono>

namespace OHOS::CalendarApi {

int64_t ReportHiEventManager::processorId = -1;
const int IDLE_TIME_OUT = 180;

ReportHiEventManager& ReportHiEventManager::getInstance() 
{
    static ReportHiEventManager instance;
    return instance;
}

ReportHiEventManager::ReportHiEventManager() 
{

}

ReportHiEventManager::~ReportHiEventManager() 
{
    stopReporting();
}

int64_t ReportHiEventManager::onApiCallStart(const std::string& api_name) 
{
    updateLastCallTime();
    if (!has_api_been_called_.exchange(true)) {
        LOG_INFO("First API call detected, API: %{public}s ", api_name.c_str());
    }

    ensureReportingRunning();

    auto& stat = getOrCreateStat(api_name);
    ++stat.total_calls;

    ++total_api_calls_;
    checkCallThreshold();

    return stat.batch_start_time.load();
}

void ReportHiEventManager::updateLastCallTime() 
{
    last_api_call_time_.store(
        std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count()
    );
}

void ReportHiEventManager::ensureReportingRunning()
{
    if (reporting_.load(std::memory_order_acquire) &&
        reporting_started_.load(std::memory_order_acquire)) {
        return;
    }

    std::lock_guard<std::mutex> lock(stats_mutex_);

    if (reporting_.load(std::memory_order_relaxed) &&
        reporting_started_.load(std::memory_order_relaxed)) {
        return;
    }

    //clear thread state
    if (thread_joinable_.load(std::memory_order_relaxed)) {
        if (report_thread_.joinable()) {
            stop_reporting_.store(true, std::memory_order_release);
            {
                std::lock_guard<std::mutex> cv_lock(report_thread_cv_mutex_);
                need_immediate_report_ = true;
            }
            report_thread_cv_.notify_one();

            if (report_thread_.joinable()) {
                report_thread_.join();
            }
            thread_joinable_.store(false, std::memory_order_release);
        }
    }

    reporting_.store(true, std::memory_order_release);
    stop_reporting_.store(false, std::memory_order_release);
    reporting_started_.store(true, std::memory_order_release);
    report_thread_ = std::thread([this]() {
        this->reportingThreadFunc();
    });
    thread_joinable_.store(true, std::memory_order_release);
}

void ReportHiEventManager::startReporting(int interval_seconds, int threshold) 
{
    if (reporting_.load()) {
        LOG_INFO("Reporting is already started.");
        return;
    }

    report_interval_seconds_ = interval_seconds;
    call_threshold_ = threshold;

    startReportingInternal();
}

void ReportHiEventManager::startReportingInternal() 
{
    if (reporting_.load()) {
        return;
    }
    reporting_ = true;
    stop_reporting_ = false;
    reporting_started_ = true;
    
    report_thread_ = std::thread([this]() {
        this->reportingThreadFunc();
    });
}

void ReportHiEventManager::stopReporting() 
{
    if (!reporting_.load()) {
        return;
    }

    reporting_ = false;
    stop_reporting_ = true;

    {
        std::lock_guard<std::mutex> lock(report_thread_cv_mutex_);
        need_immediate_report_ = true;  
    }
    report_thread_cv_.notify_one();

    if (report_thread_.joinable()) {
        report_thread_.join();
    }

    reporting_started_ = false;
    LOG_INFO("ReportHiEventManager reporting stopped");
}

void ReportHiEventManager::reportingThreadFunc() 
{
    LOG_INFO("Reporting thread started");

    auto last_report_time = std::chrono::steady_clock::now();

    while (!stop_reporting_.load()) {
        std::unique_lock<std::mutex> lock(report_thread_cv_mutex_);

        report_thread_waiting_.store(true);
        auto sleep_duration = std::chrono::seconds(1);
        bool immediate_report = report_thread_cv_.wait_for(lock, sleep_duration, 
            [this]() { return need_immediate_report_ || stop_reporting_.load(); });

        report_thread_waiting_.store(false);   
        
        bool should_report = false;
        if (immediate_report) {
            if (need_immediate_report_) {
                should_report = true;
                need_immediate_report_ = false;
            }
        }
        lock.unlock();

        if (stop_reporting_.load() || shouldAutoStop()) {
            break;
        }

        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(
            now - last_report_time).count();

        if (elapsed >= report_interval_seconds_ || should_report) {
            if (has_api_been_called_.load()) {
                performReporting();
            }
            last_report_time = now;
        }
    }

    reporting_.store(false);
    reporting_started_.store(false);
    report_thread_waiting_.store(false);
    LOG_INFO("Reporting thread exiting");
}

bool ReportHiEventManager::shouldAutoStop() const {
    if (!has_api_been_called_.load()) {
        return false; 
    }
    
    auto now = std::chrono::duration_cast<std::chrono::microseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
    auto last_call_time = last_api_call_time_.load();
    
    if (last_call_time > now) {
        return false;
    }
    
    auto idle_duration = (now - last_call_time) / 1000000; 
    return idle_duration > IDLE_TIME_OUT;
}

void ReportHiEventManager::notifyReportingThread() 
{
    if (!reporting_.load() || stop_reporting_.load()) {
        LOG_INFO("Reporting thread not active, notification ignored");
        return;
    }
    
    {
        std::lock_guard<std::mutex> lock(report_thread_cv_mutex_);
        need_immediate_report_ = true;
    }
    
    if (report_thread_waiting_.load()) {
        report_thread_cv_.notify_one();
    }
}

ApiStat& ReportHiEventManager::getOrCreateStat(const std::string& api_name) 
{
    std::lock_guard<std::mutex> lock(stats_mutex_);
    auto& stat = api_stats_[api_name];

    if (stat.batch_start_time.load() == 0) {
        stat.batch_start_time.store(std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count()
        );
    }

    return stat;
}

void ReportHiEventManager::checkCallThreshold() 
{
    int current_total_calls = total_api_calls_.load();
    if (current_total_calls >= call_threshold_) {
        notifyReportingThread();
    }
}

void ReportHiEventManager::performReporting() {
    std::lock_guard<std::mutex> lock(stats_mutex_);

    total_api_calls_.store(0);
    for (auto& [api_name, stat] : api_stats_) {
        if (stat.total_calls.load() == 0) continue;

        ReportData data;
        data.api_name = api_name;
        data.total_calls = stat.total_calls.exchange(0);
        data.batch_start_time = stat.batch_start_time.load();

        SchedulerUpload(data);

        stat.reset();
    }
    
}

int64_t ReportHiEventManager::AddProcessor()
{
    HiviewDFX::HiAppEvent::ReportConfig config;
    config.name = "ha_app_event";
    config.appId = "com_huawei_hmos_sdk_ocg";
    config.routeInfo = "https://cloudbackdown.hwcloudtest.cn";
    config.eventConfigs.clear();
    {
        HiviewDFX::HiAppEvent::EventConfig event1;
        event1.domain = "api_diagnostic";
        event1.name = "api_exec_end";
        event1.isRealTime = false;
        config.eventConfigs.push_back(event1);
    }
    {
        HiviewDFX::HiAppEvent::EventConfig event2;
        event2.domain = "api_diagnostic";
        event2.name = "api_called_stat";
        event2.isRealTime = true;
        config.eventConfigs.push_back(event2);
    }
    {
        HiviewDFX::HiAppEvent::EventConfig event3;
        event3.domain = "api_diagnostic";
        event3.name = "api_called_stat_cnt";
        event3.isRealTime = true;
        config.eventConfigs.push_back(event3);
    }
    return HiviewDFX::HiAppEvent::AppEventProcessorMgr::AddProcessor(config);
}

void ReportHiEventManager::SchedulerUpload(const ReportData& data)
{
    if (ReportHiEventManager::processorId == -1) {
        ReportHiEventManager::processorId = ReportHiEventManager::AddProcessor();
    }

    if (ReportHiEventManager::processorId == -200) {
        LOG_ERROR("Dotting Error, code -200.");
        return;
    }

    ReportHiEventManager::WriteCallStatusEvent(data);
    LOG_INFO("SchedulerUpload end.");
}

void ReportHiEventManager::WriteCallStatusEvent(const ReportData& data)
{
    HiviewDFX::HiAppEvent::Event event("api_diagnostic", "api_called_stat", OHOS::HiviewDFX::HiAppEvent::BEHAVIOR);
    event.AddParam("api_name", std::string(data.api_name));
    event.AddParam("sdk_name", std::string("CalendarKit"));
    event.AddParam("begin_time", data.batch_start_time);
    event.AddParam("call_times", data.total_calls);
    HiviewDFX::HiAppEvent::Write(event);
}
}