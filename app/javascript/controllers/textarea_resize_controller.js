import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.lastWidth = null;
    this.resize();

    // Webfonts swap in after connect and change text metrics.
    document.fonts?.ready.then(() => {
      this.resize();
    });

    // Re-measure when the column width changes (rotation, zoom, becoming
    // visible). Guard on width: our own height change also fires the observer.
    this.observer = new ResizeObserver(([entry]) => {
      const width = entry.contentRect.width;
      if (width === this.lastWidth) return;
      this.lastWidth = width;
      this.resize();
    });
    this.observer.observe(this.element);
  }

  disconnect() {
    this.observer?.disconnect();
  }

  resize() {
    const el = this.element;
    if (el.offsetParent === null) return;

    const cs = getComputedStyle(el);
    const borders =
      parseFloat(cs.borderTopWidth) + parseFloat(cs.borderBottomWidth);

    el.style.height = "auto";
    el.style.height = `${el.scrollHeight + borders}px`;
  }

  commentResize() {
    this.resize();
  }

  resetComment(event) {
    if (event.target === this.element.form) {
      requestAnimationFrame(() => {
        this.element.value = "";
        this.element.style.height = "auto";
      });
    }
  }
}
