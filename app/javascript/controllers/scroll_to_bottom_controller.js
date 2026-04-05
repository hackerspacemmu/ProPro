import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    enabled: Boolean,
    targetVersion: String,
  };

  connect() {
    // Wait for the browser to finish painting the DOM before calculating heights
    requestAnimationFrame(() => {
      setTimeout(() => {
        if (this.enabledValue) {
          this.scrollToBottom();
        } else if (this.hasTargetVersionValue) {
          this.scrollToVersion();
        }
      }, 50);
    });
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight;
  }

  scrollToVersion() {
    const targetId = `version-${this.targetVersionValue}-comments`;
    const targetElement = document.getElementById(targetId);

    if (targetElement) {
      const containerRect = this.element.getBoundingClientRect();

      const targetRect = targetElement.getBoundingClientRect();

      const scrollPosition =
        this.element.scrollTop + (targetRect.top - containerRect.top) - 20;

      this.element.scrollTo({
        top: scrollPosition,
        behavior: "smooth",
      });
    }
  }
}
