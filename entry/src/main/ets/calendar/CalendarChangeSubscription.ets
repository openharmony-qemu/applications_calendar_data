/* Copyright (c) 2026 Harmony Contrib. SPDX-License-Identifier: Apache-2.0 */
import dataShare from '@ohos.data.dataShare';
import { common } from '@kit.AbilityKit';

const URI: string = 'datashareproxy://com.ohos.calendardata/Calendars';

/** Exact provider notification URI emitted by ProviderChangeNotifier. */
export class CalendarChangeSubscription {
  private helper: dataShare.DataShareHelper | undefined = undefined;
  private pending: Promise<void> | undefined = undefined;
  private active: boolean = false;
  private epoch: number = 0;
  private readonly callback = (): void => {
    if (this.active && this.helper !== undefined) {
      console.info('CALENDAR579 ' + JSON.stringify({ event: 'provider-change', instance: this.instance,
        timestamp: Date.now(), uri: URI }));
      this.changed();
    }
  };

  private context: common.UIAbilityContext;
  private instance: string;
  private changed: () => void;
  constructor(context: common.UIAbilityContext, instance: string, changed: () => void) {
    this.context = context; this.instance = instance; this.changed = changed;
  }

  async start(): Promise<void> {
    this.active = true;
    if (this.helper !== undefined) { return; }
    if (this.pending !== undefined) {
      await this.pending;
      if (this.active && this.helper === undefined) { await this.start(); }
      return;
    }
    const epoch = this.epoch;
    this.pending = this.attach(epoch);
    try { await this.pending; } finally { this.pending = undefined; }
  }

  private async attach(epoch: number): Promise<void> {
    const helper = await dataShare.createDataShareHelper(this.context,
      'datashareproxy://com.ohos.calendardata', { isProxy: true });
    if (!this.active || epoch !== this.epoch) { await helper.close(); return; }
    try {
      helper.on('dataChange', URI, this.callback);
      this.helper = helper;
      console.info('CALENDAR579 ' + JSON.stringify({ event: 'subscribe', instance: this.instance,
        timestamp: Date.now(), uri: URI }));
    } catch (error) { await helper.close(); throw error as Error; }
  }

  stop(): void {
    this.active = false; this.epoch++;
    const helper = this.helper; this.helper = undefined;
    if (helper === undefined) { return; }
    try { helper.off('dataChange', URI, this.callback); }
    finally {
      helper.close().then(() => {
        console.info('CALENDAR579 ' + JSON.stringify({ event: 'unsubscribe', instance: this.instance,
          timestamp: Date.now(), uri: URI }));
      }).catch((error: Error) => console.error('CALENDAR579 unsubscribe error ' + error.message));
    }
  }
}

/** Per-Ability owner: onBackground stops observers synchronously even if ArkUI
 * defers a LocalStorage Watch while the page is no longer foreground. */
export class CalendarObserverLifetime {
  private stopObservers: (() => void) | undefined = undefined;
  bind(stop: () => void): void { this.stopObservers = stop; }
  stop(): void {
    const callback = this.stopObservers; this.stopObservers = undefined;
    if (callback !== undefined) { callback(); }
  }
  clear(): void { this.stopObservers = undefined; }
}
