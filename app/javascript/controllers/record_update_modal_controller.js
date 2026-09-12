import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dialog"];

  connect() {
    this.boundCloseOnBackdrop = this.closeOnBackdrop.bind(this);
    this.dialogTarget.addEventListener("click", this.boundCloseOnBackdrop);
  }

  disconnect() {
    this.dialogTarget.removeEventListener("click", this.boundCloseOnBackdrop);
  }

  open() {
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close();
  }
}
