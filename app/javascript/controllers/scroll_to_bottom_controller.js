import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    enabled: Boolean,
    targetVersion: String,
  };

  connect() {
    this.resizeObserver = new ResizeObserver(() => {
      this.position();
      this.resizeObserver.disconnect();
    });
    this.resizeObserver.observe(this.element);

    document.fonts?.ready.then(() => this.position());
  }

  disconnect() {
    this.resizeObserver?.disconnect();
  }

  position() {
    if (this.enabledValue) {
      this.element.scrollTop = this.element.scrollHeight;
    } else if (this.hasTargetVersionValue) {
      this.scrollToVersion();
    }
  }

  scrollToVersion() {
    const target = this.element.querySelector(
      `#version-${this.targetVersionValue}-comments`,
    );
    if (!target) return;

    const offset =
      target.getBoundingClientRect().top -
      this.element.getBoundingClientRect().top;
    this.element.scrollTop += offset - 20;
  }
}