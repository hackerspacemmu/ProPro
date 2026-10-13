import { Controller } from "@hotwired/stimulus";

// Page-level sticky pill navigation. While scrolling, the section currently in
// the observer band gets the active pill; on narrow screens the list scrolls so
// the active pill stays visible. Same root margins as the pre-Stimulus script.
export default class extends Controller {
  static targets = ["link", "list"];

  connect() {
    this.reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    this.sections = this.linkTargets
      .map((link) => document.getElementById(link.hash.slice(1)))
      .filter(Boolean);

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          this.linkTargets.forEach((link) => {
            const active = link.hash === `#${entry.target.id}`;
            link.classList.toggle("on", active);
            if (active) this.reveal(link);
          });
        });
      },
      { rootMargin: "-40% 0px -50% 0px" },
    );
    this.sections.forEach((section) => this.observer.observe(section));
  }

  disconnect() {
    this.observer.disconnect();
  }

  reveal(link) {
    const list = this.listTarget;
    if (list.scrollWidth <= list.clientWidth) return;
    list.scrollTo({
      left: link.offsetLeft - (list.clientWidth - link.offsetWidth) / 2,
      behavior: this.reduce.matches ? "auto" : "smooth",
    });
  }
}
