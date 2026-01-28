import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "backdrop"];

  connect() {
    // if no sidebar exists on this page, do nothing.
    if (!this.hasContainerTarget) return;

    this.checkResponsive();
    this.resizeHandler = this.checkResponsive.bind(this);
    window.addEventListener("resize", this.resizeHandler);
  }

  disconnect() {
    if (this.resizeHandler) {
      window.removeEventListener("resize", this.resizeHandler);
    }
  }

  checkResponsive() {
    if (!this.hasContainerTarget) return; // if no sidebar return

    const isDesktop = window.innerWidth >= 1024;

    if (isDesktop) {
      if (!this.containerTarget.classList.contains("lg:w-64")) {
        this.resetToDesktopDefaults();
      }
      this.hideBackdrop();
    } else {
      const userPreferClosed =
        localStorage.getItem("sidebar-collapsed") === "true";
      if (userPreferClosed) {
        this.collapse(false);
      }
    }
  }

  toggle() {
    if (!this.hasContainerTarget) return; // if no sidebar return

    if (this.containerTarget.clientWidth === 0) {
      this.expand();
    } else {
      this.collapse();
    }
  }

  collapse(animate = true) {
    if (!this.hasContainerTarget) return; // if no sidebar return

    if (animate) {
      this.containerTarget.classList.add("transition-all", "duration-200");
    }

    this.containerTarget.classList.remove("lg:w-64", "lg:opacity-100");
    this.containerTarget.classList.remove("w-64");
    this.containerTarget.classList.add("w-0");
    this.containerTarget.classList.add("overflow-hidden", "opacity-0");

    this.hideBackdrop();

    localStorage.setItem("sidebar-collapsed", "true");
  }

  expand() {
    if (!this.hasContainerTarget) return; // Safety Check

    this.containerTarget.classList.add("transition-all", "duration-300");

    this.containerTarget.classList.remove(
      "w-0",
      "overflow-hidden",
      "opacity-0",
    );
    this.containerTarget.classList.add("w-64", "opacity-100");

    if (window.innerWidth >= 1024) {
      this.containerTarget.classList.add("lg:w-64", "lg:opacity-100");
    } else {
      this.showBackdrop();
    }

    localStorage.setItem("sidebar-collapsed", "false");
  }

  resetToDesktopDefaults() {
    if (!this.hasContainerTarget) return;

    this.containerTarget.classList.remove(
      "w-0",
      "overflow-hidden",
      "opacity-0",
    );
    this.containerTarget.classList.add(
      "lg:w-64",
      "lg:opacity-100",
      "w-64",
      "opacity-100",
    );
    this.hideBackdrop();
  }

  showBackdrop() {
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("pointer-events-none", "opacity-0");
      this.backdropTarget.classList.add("opacity-100");
    }
  }

  hideBackdrop() {
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-100");
      this.backdropTarget.classList.add("pointer-events-none", "opacity-0");
    }
  }
}
