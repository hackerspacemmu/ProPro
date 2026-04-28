import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    enabled: Boolean,
    targetVersion: String,
  };

  connect() {
    // Wait until the container actually becomes visible (handles mobile tab switching)
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          // The element is now visible. Execute the scroll.
          this.performScroll();

          // Disconnect the observer so it only auto-scrolls the first time the tab is opened
          this.observer.disconnect();
        }
      });
    });

    this.observer.observe(this.element);
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  performScroll() {
    // Give the browser a tiny split-second to finish rendering the text heights
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
