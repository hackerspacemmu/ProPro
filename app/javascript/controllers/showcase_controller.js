import { Controller } from "@hotwired/stimulus";

// Landing-page showcase spike: auto-advances through a list of items, each
// with a matching screenshot frame that crossfades in. JS only toggles
// aria-current on items and data-active on frames; the crossfade itself is
// pure CSS (data-[active=true]:opacity-100). A progress bar (progress target)
// fills via requestAnimationFrame over the interval while running; it freezes
// when paused/engaged/offscreen and restarts on the next advance.
//
// Advancement runs only while the section is on screen, on a desktop-width
// viewport, with motion allowed, and neither paused nor hovered/focused.
export default class extends Controller {
  static targets = ["item", "frame", "toggle", "progress"];
  static values = {
    index: { type: Number, default: 0 },
    interval: { type: Number, default: 3000 },
    paused: { type: Boolean, default: false },
  };

  initialize() {
    this.onScreen = false;
    this.engaged = false;
    this.desktop = window.matchMedia("(min-width: 640px)");
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  }

  connect() {
    this.observer = new IntersectionObserver(
      ([entry]) => {
        this.onScreen = entry.isIntersecting;
        this.sync();
      },
      { threshold: 0.4 },
    );
    this.observer.observe(this.element);
    this.desktop.addEventListener("change", this.sync);
    this.render();
  }

  disconnect() {
    this.observer.disconnect();
    this.desktop.removeEventListener("change", this.sync);
    clearTimeout(this.timer);
    this.stopProgress();
  }

  select(event) {
    this.indexValue = this.itemTargets.indexOf(event.currentTarget);
  }

  toggle() {
    this.pausedValue = !this.pausedValue;
  }

  engage() {
    this.engaged = true;
    this.sync();
  }

  release() {
    this.engaged = false;
    this.sync();
  }

  indexValueChanged() {
    this.render();
    this.sync();
  }

  pausedValueChanged() {
    this.render();
    this.sync();
  }

  advance() {
    this.indexValue = (this.indexValue + 1) % this.itemTargets.length;
  }

  get running() {
    return (
      !this.pausedValue &&
      !this.engaged &&
      this.onScreen &&
      this.desktop.matches &&
      !this.reducedMotion.matches
    );
  }

  sync = () => {
    clearTimeout(this.timer);
    if (this.running) {
      this.timer = setTimeout(() => this.advance(), this.intervalValue);
      this.startProgress();
    } else {
      this.stopProgress();
    }
  };

  startProgress() {
    this.stopProgress();
    if (!this.hasProgressTarget) return;
    const start = performance.now();
    this.progressTarget.style.width = "0%";
    const step = (now) => {
      const progress = Math.min(
        100,
        ((now - start) / this.intervalValue) * 100,
      );
      this.progressTarget.style.width = `${progress}%`;
      if (progress < 100) this.progressFrame = requestAnimationFrame(step);
    };
    this.progressFrame = requestAnimationFrame(step);
  }

  stopProgress() {
    if (this.progressFrame) cancelAnimationFrame(this.progressFrame);
    this.progressFrame = null;
  }

  render() {
    this.itemTargets.forEach((el, i) =>
      el.setAttribute("aria-current", String(i === this.indexValue)),
    );
    this.frameTargets.forEach((el, i) => {
      el.dataset.active = String(i === this.indexValue);
      el.setAttribute("aria-hidden", String(i !== this.indexValue));
    });
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-pressed", String(this.pausedValue));
      this.toggleTarget.textContent = this.pausedValue ? "Play" : "Pause";
    }
  }
}
