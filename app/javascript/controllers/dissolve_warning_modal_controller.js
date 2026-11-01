import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.showModal();
  }

  close(e) {
    if (e) e.preventDefault();
    this.element.close();
    this.element.remove();
  }

  closeOnBackdrop(e) {
    if (e.target === this.element) {
      this.close(e);
    }
  }
}
