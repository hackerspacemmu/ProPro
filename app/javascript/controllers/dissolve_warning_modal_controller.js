import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  close(e) {
    if (e) e.preventDefault();
    this.element.remove();
  }

  closeOnBackdrop(e) {
    if (e.target === this.element) {
      this.close(e);
    }
  }
}
