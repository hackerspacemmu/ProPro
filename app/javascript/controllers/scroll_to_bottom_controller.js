import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { enabled: Boolean };

  connect() {
    if (this.enabledValue) {
      this.scrollToBottom();
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight;
  }
}
