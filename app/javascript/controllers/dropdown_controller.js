import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this);
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside);
  }

  toggle(event) {
    event.stopPropagation();
    const isVisible = !this.menuTarget.classList.contains("hidden");

    // Close all other open dropdowns first
    document
      .querySelectorAll('[data-dropdown-target="menu"]')
      .forEach((menu) => {
        if (menu !== this.menuTarget) {
          menu.classList.add("hidden");
        }
      });

    if (isVisible) {
      this.menuTarget.classList.add("hidden");
      document.removeEventListener("click", this.boundClickOutside);
    } else {
      this.menuTarget.classList.remove("hidden");
      document.addEventListener("click", this.boundClickOutside);
    }
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden");
      document.removeEventListener("click", this.boundClickOutside);
    }
  }
}
