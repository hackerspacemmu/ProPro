import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="direct-invite-modal"
export default class extends Controller {
  static targets = [
    "dialog",
    "searchInput",
    "row",
    "list",
    "hiddenInput",
    "submitButton",
    "empty",
  ];

  connect() {
    this.boundCloseOnBackdrop = this.closeOnBackdrop.bind(this);
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this);
    this.dialogTarget.addEventListener("click", this.boundCloseOnBackdrop);
  }

  disconnect() {
    this.dialogTarget.removeEventListener("click", this.boundCloseOnBackdrop);
    document.removeEventListener("click", this.boundCloseOnOutsideClick);
  }

  // ── Modal open/close ──

  open() {
    this.reset();
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  reset() {
    this.searchInputTarget.value = "";
    this.clearSelection();
    this.filterRows("");
    this.closeDropdown();
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close();
  }

  // ── Dropdown open/close ──

  onFocus(event) {
    // If we already have a selection, just select the text and keep dropdown closed
    if (this.hiddenInputTarget.value) {
      event.target.select();
      return;
    }
    // No selection yet: show the full list
    this.filterRows("");
    this.openDropdown();
  }

  onKeydown(event) {
    if (event.key !== "Escape") return;
    if (!this.listTarget.hidden) {
      event.preventDefault(); // don't let it bubble into <dialog>'s native cancel
      this.closeDropdown();
    }
  }

  openDropdown() {
    this.listTarget.hidden = false;
    this.searchInputTarget.setAttribute("aria-expanded", "true");
    document.addEventListener("click", this.boundCloseOnOutsideClick);
  }

  closeDropdown() {
    this.listTarget.hidden = true;
    this.searchInputTarget.setAttribute("aria-expanded", "false");
    document.removeEventListener("click", this.boundCloseOnOutsideClick);
  }

  closeOnOutsideClick(event) {
    if (this.searchInputTarget.contains(event.target)) return;
    if (this.listTarget.contains(event.target)) return;
    this.closeDropdown();
  }

  // ── Search / filter ──

  search() {
    // Typing = "still searching" — invalidate whatever was previously picked.
    this.clearSelection();
    this.openDropdown();
    this.filterRows(this.searchInputTarget.value.trim().toLowerCase());
  }

  filterRows(query) {
    let visible = 0;

    this.rowTargets.forEach((row) => {
      const match =
        query.length === 0 || row.dataset.name.toLowerCase().includes(query);
      row.hidden = !match;
      if (match) visible += 1;
    });

    if (this.hasEmptyTarget) this.emptyTarget.hidden = visible > 0;
  }

  // ── Selection ──

  select(event) {
    const row = event.currentTarget;
    this.searchInputTarget.value = row.dataset.name;
    this.hiddenInputTarget.value = row.dataset.userId;
    this.submitButtonTarget.disabled = false;
    this.closeDropdown();
    this.searchInputTarget.focus();
  }

  clearSelection() {
    this.hiddenInputTarget.value = "";
    this.submitButtonTarget.disabled = true;
  }
}
