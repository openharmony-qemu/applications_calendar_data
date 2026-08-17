/**
 * @file Describe the file
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

import { Log } from '@ohos/common/src/main/ets/utils/Log';
import { CalendarsColumns } from '@ohos/datastructure/src/main/ets/calendars/CalendarsColumns';
import { InstancesColumns } from '@ohos/datastructure/src/main/ets/instances/InstancesColumns';
import { EventColumns } from '@ohos/datastructure/src/main/ets/events/EventColumns';
import { RemindersColumns } from '@ohos/datastructure/src/main/ets/reminders/RemindersColumns';
import { CalendarsProcessor } from './calendars/CalendarsProcessor';
import { DatabaseProcessor } from './DatabaseProcessor';
import { DefaultProcessor } from './DefaultProcessor';
import { InstancesProcessor } from './instances/InstancesProcessor';
import { EventsProcessor } from './events/EventsProcessor';
import { AlertsObserver } from './alerts/observer/AlertsObserver';
import { AlertsObserverManager } from './alerts/observer/AlertsObserverManager';
import { RemindersProcessor } from './reminders/RemindersProcessor';

const TAG: string = "DatabaseProcessorFactory";

/**
 * the Factory of database Processors
 *
 * @since 2022-06-21
 */
class DatabaseProcessorFactory {
  getDatabaseProcessor(tableName: string): DatabaseProcessor {
    let processor: DatabaseProcessor;
    Log.info(TAG, `tableName: ${tableName}`);
    switch (tableName) {
      case CalendarsColumns.TABLE_NAME:
        processor = new CalendarsProcessor();
        break;
      case EventColumns.TABLE_NAME:
        processor = new EventsProcessor();
        break;
      case InstancesColumns.TABLE_NAME:
        processor = new InstancesProcessor();
        break;
      case RemindersColumns.TABLE_NAME:
        processor = new RemindersProcessor();
        break;
      default:
        processor = new DefaultProcessor();
        break;
    }
    if (processor instanceof DefaultProcessor) {
      AlertsObserverManager.getInstance().addObserver(AlertsObserver.getInstance());
    }
    return processor;
  }
}

export default new DatabaseProcessorFactory();