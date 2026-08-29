import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "backdrop", "toggleButton"];

  connect() {
    if (!this.hasContainerTarget) return;
    this.close();
    this.boundOnKeydown = this.onKeydown.bind(this);
    this.boundOnBeforeVisit = this.onBeforeVisit.bind(this);
    document.addEventListener("keydown", this.boundOnKeydown);
    document.addEventListener("turbo:before-visit", this.boundOnBeforeVisit);
  }

  disconnect() {
    if (!this.boundOnKeydown) return;
    document.removeEventListener("keydown", this.boundOnKeydown);
    document.removeEventListener("turbo:before-visit", this.boundOnBeforeVisit);
  }

  toggle() {
    if (this.isOpen()) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.containerTarget.classList.remove("-translate-x-full");
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden");
    }
    document.body.classList.add("overflow-hidden");
    this.setExpanded(true);
  }

  close() {
    if (!this.hasContainerTarget) return;
    this.containerTarget.classList.add("-translate-x-full");
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden");
    }
    document.body.classList.remove("overflow-hidden");
    this.setExpanded(false);
  }

  isOpen() {
    return !this.containerTarget.classList.contains("-translate-x-full");
  }

  onKeydown(event) {
    if (event.key === "Escape" && this.isOpen()) {
      this.close();
    }
  }

  onBeforeVisit() {
    this.close();
  }

  setExpanded(expanded) {
    if (!this.hasToggleButtonTarget) return;
    this.toggleButtonTarget.setAttribute("aria-expanded", String(expanded));
  }
}
