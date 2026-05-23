import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="add-member-modal"
export default class extends Controller {
  static targets = ["overlay", "form", "search", "select"];
  static values = { baseUrl: String };

  connect() {
    this.boundHandleSubmitEnd = this.handleSubmitEnd.bind(this);
    this.element.addEventListener(
      "turbo:submit-end",
      this.boundHandleSubmitEnd,
    );
  }

  disconnect() {
    this.element.removeEventListener(
      "turbo:submit-end",
      this.boundHandleSubmitEnd,
    );
  }

  // ── Open / close ────────────────────────────────────────────────────────

  open(event) {
    const btn = event.currentTarget;
    this.formTarget.action = `${this.baseUrlValue}/${btn.dataset.groupId}/members`;
    this.searchTarget.value = "";
    this.selectTarget.value = "";
    this._filterOptions("");
    this.overlayTarget.classList.remove("hidden");
    this.searchTarget.focus();
  }

  close() {
    this.overlayTarget.classList.add("hidden");
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) this.close();
  }

  // ── Search ──────────────────────────────────────────────────────────────

  filter() {
    this._filterOptions(this.searchTarget.value);
  }

  // ── Turbo Stream response handler ────────────────────────────────────────
  // Closes the modal automatically after a successful form submission.

  handleSubmitEnd(event) {
    if (event.detail.success) this.close();
  }

  // ── Private ─────────────────────────────────────────────────────────────

  _filterOptions(query) {
    const q = query.toLowerCase();
    Array.from(this.selectTarget.options).forEach((opt) => {
      // Never hide the placeholder option (value === "")
      opt.hidden = opt.value !== "" && !opt.text.toLowerCase().includes(q);
    });
  }
}
