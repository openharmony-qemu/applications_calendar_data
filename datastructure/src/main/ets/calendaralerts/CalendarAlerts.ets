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

import { util } from '@kit.ArkTS';
import { NeedAgent } from './CalendarAlertsConstants';

/**
 * the structure of table CalendarAlerts
 *
 * @since 2022-09-19
 */
export class CalendarAlerts {
  public id: number = 0;
  public eventId: number = 0;
  public eventUuid: string = '';
  public begin: number = 0;
  public end: number = 0;
  public alarmTime: number = 0;
  public creationTime: number = 0;
  public receivedTime: number = 0;
  public notifyTime: number = 0;
  public state: number = 0;
  public minutes: number = 0;
  public creator: string = '';
  public title: string = '';
  public content: string = '';
  public wantAgent: string = '';
  public buttons: string = '';
  public slotType: number = 0;
  public keepHeadsUp: number = 0;
  public type: number = 0;
  public identifier: string = '';
  public ringDuration: number = 0;
  public customRingUri: string = '';
  public timeInterval: number = 0;
  public snoozeTimes: number = 0;
  public snoozeSlotType: number = 0;
  public snoozeContent: string = '';
  public expiredContent: string = '';
  public maxScreenWantAgent: string = '';
  public accountType: string = '';
  public allDay: number = 0;
  public needAgent: NeedAgent = NeedAgent.YES;
  public uuid: string = util.generateRandomUUID();
}