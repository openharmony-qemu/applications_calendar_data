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

interface EventsType {
  id: number;
  syncId: string;
  dirty: number;
  mutators: string;
  calendarType: number;
  imageType: string;
  lastSynced: number;
  calendarId: number;
  title: string;
  eventLocation: string;
  longitude: string;
  latitude: string;
  description: string;
  eventColor: number;
  eventColorIndex: string;
  eventStatus: number;
  selfAttendeeStatus: number;
  dtStart: number;
  dtEnd: number;
  eventTimeZone: string;
  duration: string;
  allDay: number;
  accessLevel: number;
  availability: number;
  hasAlarm: number;
  hasExtendedProperties: number;
  rRule: string;
  rDate: string;
  exRule: string;
  exDate: string;
  originalId: number;
  originalSyncId: string;
  originalInstanceTime: number;
  originalAllDay: number;
  lastDate: number;
  eventTimeStamp: number;
  hasAttendeeData: number;
  guestsCanModify: number;
  guestsCanInviteOthers: number;
  guestsCanSeeGuests: number;
  organizer: string;
  isOrganizer: number;
  deleted: number;
  eventEndTimezone: string;
  customAppPackage: string;
  customAppUri: string;
  uid2445: string;
  version: number;
  eventUuid: string;
  hwExtAlertType: number;
  importantEventType: number;
  // event service
  serviceVerified: number;
  serviceType: string;
  serviceCpBzUri: string;
  serviceCpMngUri: string;
  serviceDescription: string;
  serviceSupportMinVersion: number;
  // birthdayKind
  syncData1: string;
  syncData2: string;
  syncData3: string;
  syncData4: string;
  syncData5: string;
  syncData6: string;
  syncData7: string;
  syncData8: string;
  syncData9: string;
  syncData10: string;
  kvSynced: number;
  kvSyncTime: number;
  creator: string;
}

/**
 * the structure of table Events
 *
 * @since 2022-05-28
 */
export class Events {
  public id: number = 0;
  // 邮箱账户的有值 9FTElLYEtUOcwfc25Ut5DgAAAAABDfRUxJS2BLVDnMH3NuVLeQ4AAj21rqg1
  public syncId: string = '';
  public dirty: number = 0;
  public mutators: string = '';
  // 日程是否是农历日程 1 true
  public calendarType: number = 0;
  public uuid: string = '';
  public imageType: string = '';
  public lastSynced: number = 0;
  public calendarId: number = 0;
  public title: string = '';
  public eventLocation: string = '';
  public longitude: string = '';
  public latitude: string = '';
  public description: string = '';
  public eventColor: number = 0;
  public eventColorIndex: string = '';
  public eventStatus: number = 0;
  public selfAttendeeStatus: number = 0;
  public dtStart: number = 0;
  public dtEnd: number = 0;
  public eventTimeZone: string = '';
  public duration: string = '';
  public allDay: number = 0;
  public accessLevel: number = 0;
  public availability: number = 0;
  public hasAlarm: number = 0;
  public hasExtendedProperties: number = 0;
  public rRule: string = '';
  public rDate: string = '';
  public exRule: string = '';
  public exDate: string = '';
  public originalId: number = 0;
  public originalSyncId: string = '';
  public originalInstanceTime: number = 0;
  public originalAllDay: number = 0;
  public lastDate: number = 0;
  public eventTimeStamp: number = 0;
  public hasAttendeeData: number = 0;
  public guestsCanModify: number = 0;
  public guestsCanInviteOthers: number = 0;
  public guestsCanSeeGuests: number = 0;
  public organizer: string = '';
  public isOrganizer: number = 0;
  public deleted: number = 0;
  public eventEndTimezone: string = '';
  public customAppPackage: string = '';
  public customAppUri: string = '';
  public uid2445: string = '';
  public version: number = 0;
  public eventUuid: string = '';
  public hwExtAlertType: number = 0;
  public importantEventType: number = 0;
  //一键入会相关
  public serviceVerified: number = 0;
  public serviceType: string = '';
  public serviceCpBzUri: string = '';
  public serviceCpMngUri: string = '';
  public serviceDescription: string = '';
  public serviceSupportMinVersion: number = 0;
  // birthdayKind 日程如果是属于联系人生日账户,该值表示日程的类型 10 太阳历, 11 农历
  public syncData1: string = '';
  // SYNC_DATA2 表示联系人id
  public syncData2: string = '';
  // 联系人日程有值,代码没搜到相关含义
  public syncData3: string = '';
  // 联系人日程有值,com.android.huawei.phone 联系人应用的包名
  public syncData4: string = '';
  public syncData5: string = '';
  public syncData6: string = '';
  public syncData7: string = '';
  public syncData8: string = '';
  public syncData9: string = '';
  public syncData10: string = '';
  public kvSynced: number = 0;
  public kvSyncTime: number = 0;
  public creator: string = '';
  // 双升单,提升性能，需要批量插入,oldEventId 记录原来event 主键id,
  public oldEventId: number = 0;

  // 日程唯一标识，三方写入可指定
  public identifier: string = '';

  constructor() {
  }

  /**
   * 判断是否全天日程
   *
   * @return true 全天日程 false 非全天日程
   */
  public isAllDay(): boolean {
    return this.allDay === 1;
  }
}