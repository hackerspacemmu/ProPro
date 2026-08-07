import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="invite-link"
export default class extends Controller {
  static targets = ["linkField"];

  copy() {
    if (!this.hasLinkFieldTarget) return;
    navigator.clipboard.writeText(this.linkFieldTarget.value);
  }
}