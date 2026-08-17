import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="group-browse-filter"
export default class extends Controller {
  static targets = ["tab", "card", "searchInput"]
  static values = { status: { type: String, default: "all" } }

  connect() {
    this.applyFilters()
  }

  selectTab(event) {
    this.statusValue = event.currentTarget.dataset.status

    this.tabTargets.forEach((tab) => {
      const active = tab === event.currentTarget
      tab.classList.toggle("bg-zinc-900", active)
      tab.classList.toggle("text-white", active)
      tab.classList.toggle("text-gray-500", !active)
    })

    this.applyFilters()
  }

  search() {
    this.applyFilters()
  }

  applyFilters() {
    const query = this.hasSearchInputTarget
      ? this.searchInputTarget.value.trim().toLowerCase()
      : ""

    this.cardTargets.forEach((card) => {
      const statusMatch =
        this.statusValue === "all" || card.dataset.status === this.statusValue
      const searchMatch =
        query === "" || (card.dataset.searchText || "").includes(query)

      card.classList.toggle("hidden", !(statusMatch && searchMatch))
    })
  }
}