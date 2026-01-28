import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  // Open the overlay
  open(e) {
    e.preventDefault();
    this.menuTarget.classList.remove("hidden");
    document.body.classList.add("overflow-hidden");
  }

  // Close the overlay
  close(e) {
    if (e) e.preventDefault();
    this.menuTarget.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");
  }

  // Close when clicking outsite of the ovelay
  closeOnBackdrop(e) {
    if (e.target === this.menuTarget) {
      this.close();
    }
  }
}
