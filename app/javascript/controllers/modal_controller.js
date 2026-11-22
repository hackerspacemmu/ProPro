import { Controller } from "@hotwired/stimulus";

// Generic <dialog>-based modal. Wire any button with data-action="modal#open"
// and the dialog itself with data-action="modal#close" / the backdrop click
// fallthrough closes on a click that lands on the dialog element itself.
// Optional frame target: reset() restores the placeholder markup and clears
// the lazy-loaded frame, so reopening a Manage dialog never shows stale data.
export default class extends Controller {
  static targets = ["dialog", "frame"];

  connect() {
    if (this.hasFrameTarget) {
      this.framePlaceholder = this.frameTarget.innerHTML;
    }
  }

  open() {
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  closeOnSuccess(event) {
    if (event.detail.success) this.close();
  }

  reset() {
    if (!this.hasFrameTarget) return;

    this.frameTarget.innerHTML = this.framePlaceholder;
    this.frameTarget.removeAttribute("src");
    this.frameTarget.removeAttribute("complete");
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close();
  }
}
