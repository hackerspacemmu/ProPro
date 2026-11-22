import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="invite-link"
export default class extends Controller {
  static targets = ["linkField", "button"];

  copy() {
    if (!this.hasLinkFieldTarget) return;

    const restore = () => {
      if (!this.hasButtonTarget) return;
      this.buttonTarget.textContent =
        this.buttonTarget.dataset.originalLabel || "Copy link";
    };

    if (this.hasButtonTarget) {
      this.buttonTarget.dataset.originalLabel ||= this.buttonTarget.textContent;
    }

    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(this.linkFieldTarget.value).then(() => {
        if (this.hasButtonTarget) this.buttonTarget.textContent = "Copied";
        window.setTimeout(restore, 2000);
      });
      return;
    }

    this.linkFieldTarget.select();
    if (this.hasButtonTarget) this.buttonTarget.textContent = "Copy";
  }
}
