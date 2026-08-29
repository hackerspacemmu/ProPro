import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "backdrop", "trigger"];

  close() {
    this.panelTarget.classList.add("translate-x-full");
    this.backdropTarget.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");
    this.setExpanded(false);
  }

  open() {
    this.panelTarget.classList.remove("translate-x-full");
    this.backdropTarget.classList.remove("hidden");
    document.body.classList.add("overflow-hidden");
    this.setExpanded(true);
  }

  toggle() {
    if (this.panelTarget.classList.contains("translate-x-full")) {
      this.open();
    } else {
      this.close();
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close();
  }

  setExpanded(expanded) {
    if (!this.hasTriggerTarget) return;
    this.triggerTarget.setAttribute("aria-expanded", String(expanded));
  }
}
