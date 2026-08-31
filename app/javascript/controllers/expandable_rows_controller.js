import { Controller } from "@hotwired/stimulus";

// Row expand/collapse for the Groups table (member list hidden behind an
// avatar stack) plus a header toggle for expand/collapse-all. Generic — does
// not reference the groups table by name.
//
// The tbody content is swapped by htmx for search/filter/sort, so this uses
// delegated listeners on the controller element plus querySelector lookups —
// no row targets — so toggles keep working after a swap. The header toggle
// is wired through the same delegated path via [data-expandable-toggle-all]
// rather than a Stimulus data-action (single code path, no th event
// inference).
export default class extends Controller {
  connect() {
    this.onClick = this.onClick.bind(this);
    this.element.addEventListener("click", this.onClick);
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick);
  }

  onClick(event) {
    if (event.target.closest("[data-expandable-toggle-all]")) {
      this.toggleAll();
      return;
    }

    const row = event.target.closest("[data-row-id]");
    if (!row) return;
    if (event.target.closest("a")) return;

    this.toggleRow(row.dataset.rowId);
  }

  toggleRow(id) {
    const detail = this.element.querySelector(
      `[data-detail-row-id="${CSS.escape(id)}"]`,
    );
    if (!detail) return;

    const expand = detail.classList.contains("hidden");
    detail.classList.toggle("hidden", !expand);

    const row = this.element.querySelector(
      `tr[data-row-id="${CSS.escape(id)}"]`,
    );
    const chevron = row?.querySelector("[data-row-chevron]");
    if (chevron) chevron.classList.toggle("rotate-180", expand);
  }

  toggleAll() {
    const allExpanded = !this.element.querySelector(
      "[data-detail-row-id]:not(.hidden)",
    );
    this.element
      .querySelectorAll("[data-detail-row-id]")
      .forEach((detail) => detail.classList.toggle("hidden", !allExpanded));
    this.element
      .querySelectorAll("[data-row-chevron]")
      .forEach((chevron) =>
        chevron.classList.toggle("rotate-180", allExpanded),
      );

    const toggleAllIcon = this.element.querySelector(
      "#groups-table-toggle-all",
    );
    if (toggleAllIcon) {
      toggleAllIcon.textContent = allExpanded ? "unfold_less" : "unfold_more";
    }
  }
}
