/* Copyright (c) 2026 Harmony Contrib. SPDX-License-Identifier: Apache-2.0 */
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import { EventEditorController } from './editor/EventEditorController';

export default class EditorUIExtensionAbility extends UIExtensionAbility {
  private editors: Map<UIExtensionContentSession, EventEditorController> = new Map();

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    let editor: EventEditorController;
    try {
      editor = new EventEditorController(this.context, session, want.parameters?.event as string);
    } catch (error) {
      this.fail(session, 401, 'Invalid calendar event');
      return;
    }
    this.editors.set(session, editor);
    try {
      const storage: LocalStorage = new LocalStorage();
      storage.setOrCreate<EventEditorController>('editor', editor);
      session.loadContent('pages/EventEditor', storage);
    } catch (error) {
      editor.dispose();
      this.editors.delete(session);
      this.fail(session, 23900004, 'Calendar editor could not be displayed');
    }
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    this.editors.get(session)?.dispose();
    this.editors.delete(session);
  }

  onDestroy(): void {
    this.editors.forEach((editor: EventEditorController) => editor.dispose());
    this.editors.clear();
  }

  private fail(session: UIExtensionContentSession, code: number, message: string): void {
    session.terminateSelfWithResult({
      resultCode: code,
      want: { parameters: { errorCode: code, errorMessage: message } }
    }).catch(() => console.error('Calendar editor result delivery failed'));
  }
}
