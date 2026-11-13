/* Copyright (c) 2026 Harmony Contrib. SPDX-License-Identifier: Apache-2.0 */
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import util from '@ohos.util';
import { CalendarObserverLifetime } from '../calendar/CalendarChangeSubscription';

export default class MainAbility extends UIAbility {
  private storage: LocalStorage = new LocalStorage();
  private revision: number = 0;
  private visible: boolean = false;
  private instance: string = util.generateRandomUUID();
  private observerLifetime: CalendarObserverLifetime = new CalendarObserverLifetime();

  private observe(event: string, uri: string = ''): void {
    console.info('CALENDAR579 ' + JSON.stringify({ event: event, instance: this.instance,
      revision: this.revision, timestamp: Date.now(), uri: uri }));
  }

  onCreate(want: Want): void {
    this.storage.setOrCreate<string>('calendarInstance', this.instance);
    this.storage.setOrCreate<CalendarObserverLifetime>('calendarObserverLifetime', this.observerLifetime);
    this.observe('onCreate', want.uri ?? '');
    this.storage.setOrCreate<boolean>('calendarForeground', false);
    this.storage.setOrCreate<string>('calendarRoute', want.uri ?? '');
    this.storage.setOrCreate<number>('calendarRevision', ++this.revision);
  }

  onNewWant(want: Want): void {
    this.observe('onNewWant', want.uri ?? '');
    this.storage.setOrCreate<string>('calendarRoute', want.uri ?? '');
    this.storage.setOrCreate<number>('calendarRevision', ++this.revision);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.observe('onWindowStageCreate');
    this.storage.setOrCreate<boolean>('calendarForeground', this.visible);
    this.storage.setOrCreate<number>('calendarRevision', ++this.revision);
    windowStage.loadContent('pages/index', this.storage);
  }

  onForeground(): void {
    this.observe('onForeground');
    this.visible = true;
    this.storage.setOrCreate<boolean>('calendarForeground', true);
    this.storage.setOrCreate<number>('calendarRevision', ++this.revision);
  }

  onBackground(): void {
    this.observe('onBackground');
    this.observerLifetime.stop();
    this.visible = false;
    this.storage.setOrCreate<boolean>('calendarForeground', false);
    this.storage.setOrCreate<number>('calendarRevision', ++this.revision);
  }

  onWindowStageDestroy(): void {
    this.observe('onWindowStageDestroy');
    this.observerLifetime.stop();
    this.storage.setOrCreate<boolean>('calendarForeground', false);
    this.storage.setOrCreate<number>('calendarRevision', ++this.revision);
  }

  onDestroy(): void {
    this.observe('onDestroy');
    this.observerLifetime.stop();
    this.visible = false;
    this.storage.setOrCreate<boolean>('calendarForeground', false);
    this.storage.setOrCreate<string>('calendarRoute', '');
    this.storage.setOrCreate<number>('calendarRevision', ++this.revision);
  }
}
