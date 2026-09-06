import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static DESKTOP_QUERY = "(min-width: 1024px)";
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

  // Breakpoint-aware: below lg the sidebar is the off-canvas drawer (existing
  // behavior, untouched); at lg+ it is a collapsible rail driven by the
  // data-collapsed attribute (CSS variants, no width-class juggling).
  toggle() {
    if (this.isDesktop()) {
      this.setCollapsed(!this.isCollapsed());
    } else if (this.isOpen()) {
      this.close();
    } else {
      this.open();
    }
  }

  isDesktop() {
    return window.matchMedia(this.constructor.DESKTOP_QUERY).matches;
  }

  isCollapsed() {
    return this.containerTarget.dataset.collapsed === "true";
  }

  setCollapsed(value) {
    this.containerTarget.dataset.collapsed = String(value);
    // Same write tabs_controller.js uses for the active tab cookie (plain,
    // samesite=lax, secure only over https): do not simplify — keep the
    // app's one persistence convention.
    const secure = window.location.protocol === "https:" ? "; secure" : "";
    document.cookie = `propro_sidebar_rail_collapsed=${value}; path=/; max-age=31536000; samesite=lax${secure}`;
    this.syncExpanded();
  }

  open() {
    this.containerTarget.classList.remove("-translate-x-full");
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden");
    }
    document.body.classList.add("overflow-hidden");
    this.syncExpanded();
  }

  close() {
    if (!this.hasContainerTarget) return;
    this.containerTarget.classList.add("-translate-x-full");
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden");
    }
    document.body.classList.remove("overflow-hidden");
    this.syncExpanded();
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

  // aria-expanded must reflect whichever state is relevant at the current
  // breakpoint: the mobile drawer below lg, the expanded rail at lg+.
  syncExpanded() {
    if (!this.hasToggleButtonTarget) return;
    const open = this.isDesktop() ? !this.isCollapsed() : this.isOpen();
    this.toggleButtonTarget.setAttribute("aria-expanded", String(open));
  }
}
