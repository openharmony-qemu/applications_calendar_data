/* Copyright (c) 2026 Harmony Contrib. SPDX-License-Identifier: Apache-2.0 */
import { EventEditorController } from '../editor/EventEditorController';

@Entry({ useSharedStorage: true })
@Component
struct EventEditor {
  @LocalStorageProp('editor') private editor: EventEditorController | undefined = undefined;
  @State private title: string = '';
  @State private start: string = '';
  @State private end: string = '';
  @State private description: string = '';
  @State private error: string = '';
  @State private saving: boolean = false;
  @State private persisted: boolean = false;

  aboutToAppear(): void {
    if (this.editor !== undefined) {
      this.title = this.editor.event.title ?? '';
      this.start = new Date(this.editor.event.startTime).toISOString();
      this.end = new Date(this.editor.event.endTime).toISOString();
      this.description = this.editor.event.description ?? '';
    }
  }

  private async save(): Promise<void> {
    if (this.editor === undefined || this.saving) {
      return;
    }
    this.saving = true;
    await this.editor.save(this.title, this.start, this.end, this.description);
    this.error = this.editor.error;
    this.persisted = this.editor.eventId > 0;
    this.saving = false;
  }

  private async cancel(): Promise<void> {
    await this.editor?.cancel();
    this.error = this.editor?.error ?? '';
  }

  onBackPress(): boolean {
    if (!this.saving) {
      this.cancel();
    }
    return true;
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('新建日程').fontSize(24).fontWeight(FontWeight.Bold).id('calendar-editor-title');
        Text('应用请求创建日程，请检查内容后保存。取消不会创建日程。').fontSize(16);
        TextInput({ text: this.title, placeholder: '标题' }).id('calendar-editor-event-title')
          .maxLength(5000).enabled(!this.saving && !this.persisted)
          .onChange((value: string) => this.title = value);
        Text('开始时间（UTC，ISO 8601）');
        TextInput({ text: this.start }).id('calendar-editor-start').enabled(!this.saving && !this.persisted)
          .onChange((value: string) => this.start = value);
        Text('结束时间（UTC，ISO 8601）');
        TextInput({ text: this.end }).id('calendar-editor-end').enabled(!this.saving && !this.persisted)
          .onChange((value: string) => this.end = value);
        TextArea({ text: this.description, placeholder: '备注' }).id('calendar-editor-description')
          .maxLength(5000).enabled(!this.saving && !this.persisted)
          .onChange((value: string) => this.description = value);
        if (this.editor?.event.isAllDay) {
          Text('全天日程');
        }
        if (this.editor?.event.location !== undefined) {
          Text(`地点：${this.editor?.event.location?.location ?? ''}`);
        }
        if (this.editor?.event.reminderTime !== undefined) {
          Text(`提醒（提前分钟）：${this.editor?.event.reminderTime?.join(', ')}`);
        }
        if (this.editor?.event.recurrenceRule !== undefined) {
          Text(`重复规则：${JSON.stringify(this.editor?.event.recurrenceRule)}`);
        }
        if (this.error.length > 0) {
          Text(this.error).fontColor(Color.Red).id('calendar-editor-error');
        }
        Row({ space: 16 }) {
          Button(this.persisted ? '返回日程' : '保存').id('calendar-editor-save')
            .enabled(!this.saving && this.editor !== undefined).onClick(() => this.save());
          Button('取消').id('calendar-editor-cancel').enabled(!this.saving && !this.persisted)
            .onClick(() => this.cancel());
        }
      }.padding(24).width('100%').alignItems(HorizontalAlign.Start);
    }.width('100%').height('100%').backgroundColor(Color.White);
  }
}
