import { Controller } from "@hotwired/stimulus"

// connects to data-controller="combobox-modal"
export default class extends Controller {
  static targets = ["dialog", "searchInput", "list", "row", "empty", "hiddenInput", "submitButton"]

  // ── Modal open/close ──

  open() {
    this.reset()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  reset() {
    this.searchInputTarget.value = ""
    this.clearSelection()
    this.filterRows("")
    this.closeDropdown()
  }

  // Bound via data-action on the <dialog> itself — clicking the ::backdrop
  // fires a click whose target is the dialog element; inner content doesn't.
  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  // ── Dropdown open/close ──

  onFocus(event) {
    // Already have a selection — just select the text, don't reopen the list.
    if (this.hiddenInputTarget.value) {
      event.target.select()
      return
    }
    this.filterRows("")
    this.openDropdown()
  }

  onKeydown(event) {
    if (event.key !== "Escape") return
    if (!this.listTarget.hidden) {
      event.preventDefault() // close the dropdown only, not the <dialog>
      this.closeDropdown()
    }
  }

  openDropdown() {
    this.listTarget.hidden = false
    this.searchInputTarget.setAttribute("aria-expanded", "true")
  }

  closeDropdown() {
    this.listTarget.hidden = true
    this.searchInputTarget.setAttribute("aria-expanded", "false")
  }

  // data-action="click@document->combobox-modal#closeOnOutsideClick"
  // Stimulus binds/unbinds this to document automatically on connect/disconnect.
  closeOnOutsideClick(event) {
    if (this.searchInputTarget.contains(event.target)) return
    if (this.listTarget.contains(event.target)) return
    this.closeDropdown()
  }

  // ── Search / filter ──

  search() {
    this.clearSelection() // typing invalidates a prior pick
    this.openDropdown()
    this.filterRows(this.searchInputTarget.value.trim().toLowerCase())
  }

  filterRows(query) {
    let visible = 0
    this.rowTargets.forEach((row) => {
      const match = query.length === 0 || row.dataset.name.toLowerCase().includes(query)
      row.hidden = !match
      if (match) visible += 1
    })
    if (this.hasEmptyTarget) this.emptyTarget.hidden = visible > 0
  }

  // ── Selection ──

  select(event) {
    const row = event.currentTarget
    this.searchInputTarget.value = row.dataset.name
    this.hiddenInputTarget.value = row.dataset.userId
    this.submitButtonTarget.disabled = false
    this.closeDropdown()
    this.searchInputTarget.focus()
  }

  clearSelection() {
    this.hiddenInputTarget.value = ""
    this.submitButtonTarget.disabled = true
  }
}