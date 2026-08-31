import { Controller } from "@hotwired/stimulus";

// Generic <dialog>-based modal. Wire any button with data-action="modal#open"
// and the dialog itself with data-action="modal#close" / the backdrop click
// fallthrough closes on a click that lands on the dialog element itself.
export default class extends Controller {
  static targets = ["dialog"];

  open() {
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close();
  }
}