import { Controller } from "@hotwired/stimulus";

// Lightweight client-side filtering for dialog/picker lists: search text,
// optional select tags, an optional "show first N" cap, and live counts.
// The server-filtered group table uses htmx instead.
export default class extends Controller {
  static targets = [
    "input",
    "select",
    "item",
    "shown",
    "total",
    "noMatch",
    "empty",
    "container",
  ];
  static values = { limit: { type: Number, default: 0 } };

  connect() {
    this.apply();
  }

  filter() {
    this.apply();
  }

  apply() {
    const query = this.hasInputTarget
      ? this.inputTarget.value.trim().toLowerCase()
      : "";
    const selected = this.hasSelectTarget ? this.selectTarget.value : "all";

    let matched = 0;
    let visible = 0;
    this.itemTargets.forEach((item) => {
      const text = item.dataset.listFilterText || "";
      const tags = (item.dataset.listFilterTags || "").split(" ");
      const textMatch = query.length === 0 || text.includes(query);
      const tagMatch = selected === "all" || tags.includes(selected);
      const match = textMatch && tagMatch;
      const show =
        match && (this.limitValue === 0 || visible < this.limitValue);

      item.classList.toggle("hidden", !show);
      if (match) matched += 1;
      if (show) visible += 1;
    });

    const hasItems = this.itemTargets.length > 0;

    if (this.hasShownTarget) this.shownTarget.textContent = visible;
    if (this.hasTotalTarget) this.totalTarget.textContent = matched;
    if (this.hasNoMatchTarget)
      this.noMatchTarget.classList.toggle("hidden", !hasItems || matched > 0);
    if (this.hasEmptyTarget)
      this.emptyTarget.classList.toggle("hidden", hasItems);
    if (this.hasContainerTarget)
      this.containerTarget.classList.toggle("hidden", visible === 0);

    this.element.dispatchEvent(
      new CustomEvent("list-filter:change", {
        bubbles: true,
        detail: {
          active: query.length > 0 || selected !== "all",
          visible,
          total: matched,
        },
      }),
    );
  }
}
