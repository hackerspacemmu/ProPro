import { Controller } from "@hotwired/stimulus";

// Row expand/collapse for block-shaped collapsible lists: the Groups table
// (member list hidden behind an avatar stack) and the Topics Directory
// supervisor groups. Generic — does not reference either by name.
//
// A "row" pair is a header carrying [data-row-id] with a following detail
// carrying [data-detail-row-id="<same id>"] (a <tr> in the Groups table, a
// hidden side body in the supervisor groups). The optional expand/collapse-all
// control is [data-expandable-toggle-all] with [data-expandable-all-icon] and
// [data-expandable-all-label] ("Collapse all"/"Expand all").
//
// Content is swapped by htmx for search/filter/sort, so this uses delegated
// listeners on the controller element plus querySelector lookups — no row
// targets — so toggles keep working after a swap. Both consumers render their
// rows either all-expanded or all-collapsed, and the toggle-all control is
// wired through the same delegated path as row toggles (single code path, no
// Stimulus event inference).
export default class extends Controller {
  connect() {
    this.onClick = this.onClick.bind(this);
    this.element.addEventListener("click", this.onClick);
    this.syncToggleAll();
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
      `[data-row-id="${CSS.escape(id)}"]`,
    );
    const chevron = row?.querySelector("[data-row-chevron]");
    if (chevron) chevron.classList.toggle("rotate-180", expand);
  }

  toggleAll() {
    this.element
      .querySelectorAll("[data-detail-row-id]")
      .forEach((detail) => {
        const collapsed = detail.classList.toggle("hidden");
        const row = this.element.querySelector(
          `[data-row-id="${CSS.escape(detail.dataset.detailRowId)}"]`,
        );
        const chevron = row?.querySelector("[data-row-chevron]");
        if (chevron) chevron.classList.toggle("rotate-180", !collapsed);
      });

    this.syncToggleAll();
  }

  syncToggleAll() {
    const allCollapsed = !this.element.querySelector(
      "[data-detail-row-id]:not(.hidden)",
    );

    const icon = this.element.querySelector("[data-expandable-all-icon]");
    if (icon) icon.textContent = allCollapsed ? "unfold_more" : "unfold_less";

    const label = this.element.querySelector("[data-expandable-all-label]");
    if (label) label.textContent = allCollapsed ? "Expand all" : "Collapse all";
  }
}
