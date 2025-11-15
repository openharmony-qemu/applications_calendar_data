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
#include "dotting_manager.h"
#include "calendar_log.h"

namespace OHOS::CalendarApi {

int64_t DottingManager::processorId = -1;

DottingManager& DottingManager::getInstance() 
{
    static DottingManager instance;
    return instance;
}

DottingManager::DottingManager() 
{

}

DottingManager::~DottingManager() 
{
    stopReporting();
}

int64_t DottingManager::onApiCallStart(const std::string& api_name) 
{
    if (!has_api_been_called_.exchange(true)) {
        LOG_INFO("First API call detected, API: %{public}s ", api_name.c_str());
    }

    if (!reporting_started_.load() && !reporting_.load()) {
        std::lock_guard<std::mutex> lock(stats_mutex_);
        if (!reporting_started_.load() && !reporting_.load()) {
            LOG_INFO("Auto starting reporting on first API call ");
            startReportingInternal();
        }
    }

    auto& stat = getOrCreateStat(api_name);
    ++stat.total_calls;

    ++total_api_calls_;
    checkCallThreshold();

    return stat.batch_start_time.load();
}

void DottingManager::onApiCallSuccess(const std::string& api_name) 
{
    auto& stat = getOrCreateStat(api_name);
    ++stat.success_calls;
}

void DottingManager::onApiCallError(const std::string& api_name, const std::string& error_code) 
{
    auto& stat = getOrCreateStat(api_name);
    stat.addErrorCode(error_code);
}

void DottingManager::startReporting(int interval_seconds, int threshold) 
{
    if (reporting_.load()) {
        LOG_INFO("Reporting is already started.");
        return;
    }

    report_interval_seconds_ = interval_seconds;
    call_threshold_ = threshold;

    startReportingInternal();
}

void DottingManager::startReportingInternal() 
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

void DottingManager::stopReporting() 
{
    if (!reporting_.load()) {
        return;
    }

    reporting_ = false;
    stop_reporting_ = true;
    reporting_started_ = false;

    if (report_thread_.joinable()) {
        report_thread_.join();
    }

    LOG_INFO("DottingManger reporting stopped");
}

void DottingManager::reportingThreadFunc() 
{
    LOG_INFO("Reporting thread started");

    auto last_report_time = std::chrono::steady_clock::now();

    while (!stop_reporting_.load()) {
        std::this_thread::sleep_for(std::chrono::seconds(1));

        if (stop_reporting_.load()) {
            break;
        }

        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(
            now - last_report_time).count();

        if (elapsed >= report_interval_seconds_) {
            if (has_api_been_called_.load()) {
                performReporting();
            }
            last_report_time = now;
        }
    }
    LOG_INFO("Reporting thread exiting");
}

ApiStat& DottingManager::getOrCreateStat(const std::string& api_name) 
{
    std::lock_guard<std::mutex> lock(stats_mutex_);
    auto& stat = api_stats_[api_name];

    if (stat.batch_start_time.load() == 0) {
        stat.batch_start_time.store(std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count()
        );
    }

    return stat;
}

void DottingManager::checkCallThreshold() 
{
    int current_total_calls = total_api_calls_.load();
    if (current_total_calls >= call_threshold_) {
        performReporting();
    }
}

void DottingManager::performReporting() {
    std::lock_guard<std::mutex> lock(stats_mutex_);

    total_api_calls_.store(0);
    for (auto& [api_name, stat] : api_stats_) {
        if (stat.total_calls.load() == 0) continue;

        ReportData data;
        data.api_name = api_name;
        data.total_calls = stat.total_calls.exchange(0);
        data.success_calls = stat.success_calls.exchange(0);
        data.batch_start_time = stat.batch_start_time.load();

        {
            std::lock_guard<std::mutex> error_lock(stat.error_mutex);
            data.error_code_types = stat.error_code_types;
            data.error_code_num = stat.error_code_num;
            stat.error_code_types.clear();
            stat.error_code_num.clear();
        }

        SchedulerUpload(data);

        stat.reset();

        auto now = std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count();
        if (now - stat.batch_start_time.load() > 300000000) {
            stat.batch_start_time.store(0);
        }
    }

    
}

int64_t DottingManager::AddProcessor()
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

void DottingManager::SchedulerUpload(const ReportData& data)
{
    if (DottingManager::processorId == -1) {
        DottingManager::processorId = DottingManager::AddProcessor();
    }

    if (DottingManager::processorId == -200) {
        LOG_ERROR("Dotting Error, code -200.");
        return;
    }

    DottingManager::WriteCallStatusEvent(data);
    LOG_INFO("SchedulerUpload end.");
}

void DottingManager::WriteCallStatusEvent(const ReportData& data)
{
    HiviewDFX::HiAppEvent::Event event("api_diagnostic", "api_called_stat", OHOS::HiviewDFX::HiAppEvent::BEHAVIOR);
    event.AddParam("api_name", std::string(data.api_name));
    event.AddParam("sdk_name", std::string("CalendarKit"));
    event.AddParam("begin_time", data.batch_start_time);
    event.AddParam("call_times", data.total_calls);
    event.AddParam("sucess_times", data.success_calls);
    event.AddParam("error_code_types", data.error_code_types);
    event.AddParam("min_cost_time", data.error_code_num);
    HiviewDFX::HiAppEvent::Write(event);
}
}