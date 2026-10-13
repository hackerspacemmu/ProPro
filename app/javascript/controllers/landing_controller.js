import { Controller } from "@hotwired/stimulus";

// One instance per feature section (data-controller="landing"). Auto-advances
// through the items: the active item stays open while its fill bar grows over
// the interval, then the next item opens and the media image swaps. Advancement
// only runs while the section is on screen and motion is allowed; on coarse-
// pointer devices a first tap or swipe stops it for good. The panel's height is
// pinned to the tallest open item so the page does not jump. disconnect() tears
// down every rAF, observer and listener so Turbo navigation never leaks timers.
export default class extends Controller {
  static targets = ["item", "media", "image", "fill", "panel"];
  static values = { interval: { type: Number, default: 7000 } };

  connect() {
    this.connected = true;
    this.cur = 0;
    this.visible = false;
    this.paused = false;
    this.touchX = null;
    this.touchY = null;
    this.start = performance.now();
    this.frame = null;
    this.resizeTimer = null;
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)");
    this.coarse = window.matchMedia("(hover: none)");

    this.observer = new IntersectionObserver(
      ([entry]) => {
        this.visible = entry.isIntersecting;
        if (this.visible) this.start = performance.now();
      },
      { threshold: 0.4 },
    );
    this.observer.observe(this.element);

    this.itemTargets.forEach((item) =>
      item.addEventListener("click", this.onItemClick),
    );
    this.mediaTarget.addEventListener("touchstart", this.onTouchStart, {
      passive: true,
    });
    this.mediaTarget.addEventListener("touchend", this.onTouchEnd, {
      passive: true,
    });

    this.resizeObserver = new ResizeObserver(this.lockHeights);
    this.resizeObserver.observe(this.panelTarget);
    window.addEventListener("resize", this.onResize);
    if (document.fonts && document.fonts.ready)
      document.fonts.ready.then(this.lockHeights);

    this.select(0);
    this.lockHeights();
    this.tick();
  }

  disconnect() {
    this.connected = false;
    this.observer.disconnect();
    this.resizeObserver.disconnect();
    cancelAnimationFrame(this.frame);
    clearTimeout(this.resizeTimer);
    window.removeEventListener("resize", this.onResize);
    this.itemTargets.forEach((item) =>
      item.removeEventListener("click", this.onItemClick),
    );
    this.mediaTarget.removeEventListener("touchstart", this.onTouchStart);
    this.mediaTarget.removeEventListener("touchend", this.onTouchEnd);
  }

  select = (i) => {
    this.cur = i;
    this.start = performance.now();
    const animate = !this.reduced.matches && !this.paused;
    this.itemTargets.forEach((item, k) => {
      const open = k === i;
      item.classList.toggle("open", open);
      item.setAttribute("aria-expanded", String(open));
      this.fillTargets[k].style.height = open && animate ? "0" : "100%";
    });
    const title = this.itemTargets[i].querySelector(".t").textContent;
    this.mediaTarget.setAttribute("aria-label", `Enlarge screenshot: ${title}`);
    const src = this.itemTargets[i].getAttribute("data-img");
    if (src && this.hasImageTarget) {
      this.imageTarget.src = src;
      this.imageTarget.alt = title;
    }
  };

  onItemClick = (event) => {
    if (this.coarse.matches) this.paused = true;
    this.select(this.itemTargets.indexOf(event.currentTarget));
  };

  onTouchStart = (event) => {
    const touch = event.changedTouches[0];
    this.touchX = touch.clientX;
    this.touchY = touch.clientY;
  };

  onTouchEnd = (event) => {
    const touch = event.changedTouches[0];
    const dx = touch.clientX - this.touchX;
    const dy = touch.clientY - this.touchY;
    if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy) * 1.5) {
      this.paused = true;
      this.select(
        (this.cur + (dx < 0 ? 1 : -1) + this.itemTargets.length) %
          this.itemTargets.length,
      );
    }
  };

  onResize = () => {
    clearTimeout(this.resizeTimer);
    this.resizeTimer = setTimeout(this.lockHeights, 150);
  };

  // Pin the panel to the height of its tallest open item so expanding an item
  // does not reflow the page. Idempotent: re-running sets the same value.
  lockHeights = () => {
    if (!this.connected) return;
    this.panelTarget.style.minHeight = "";
    let max = 0;
    this.itemTargets.forEach((candidate, k) => {
      this.itemTargets.forEach((other, j) =>
        other.classList.toggle("open", j === k),
      );
      max = Math.max(max, this.panelTarget.offsetHeight);
    });
    this.itemTargets.forEach((other, j) =>
      other.classList.toggle("open", j === this.cur),
    );
    this.panelTarget.style.minHeight = `${max}px`;
  };

  tick = () => {
    if (this.visible && !this.reduced.matches && !this.paused) {
      const progress = Math.min(
        (performance.now() - this.start) / this.intervalValue,
        1,
      );
      this.fillTargets[this.cur].style.height = `${progress * 100}%`;
      if (progress >= 1) this.select((this.cur + 1) % this.itemTargets.length);
    }
    this.frame = requestAnimationFrame(this.tick);
  };
}
