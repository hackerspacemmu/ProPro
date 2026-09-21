import { Controller } from "@hotwired/stimulus";

// Expand/collapse for the Overview tab's sections (Supervised Projects,
// Pending Proposals, Reviewed Proposals, Pending Topics) plus the
// Collapse all / Expand all header toggle.
//
// Each section pairs a header ([data-collapsible-sections-target="toggle"])
// with its row-list body ([data-collapsible-sections-target="body"]) by a
// shared data-collapsible-sections-section value — the same pairing mental
// model as expandable-rows, but block-shaped and independent of the Groups
// table (which htmx-swaps its tbody). Sections load expanded (per the
// mockup); no state persistence.
export default class extends Controller {
  static targets = ["toggle", "body", "toggleAllIcon", "toggleAllLabel"];

  toggle(event) {
    const header = event.currentTarget;
    const body = this.findBody(header.dataset.collapsibleSectionsSection);
    if (!body) return;

    const collapsed = body.classList.toggle("hidden");
    this.setChevron(header, collapsed);
    this.syncToggleAll();
  }

  onKeydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return;
    event.preventDefault();
    this.toggle(event);
  }

  toggleAll() {
    const allCollapsed = this.bodyTargets.every((body) =>
      body.classList.contains("hidden"),
    );
    const expand = allCollapsed;

    this.bodyTargets.forEach((body) => {
      const collapsed = !expand;
      body.classList.toggle("hidden", collapsed);
      const header = this.findToggle(body.dataset.collapsibleSectionsSection);
      if (header) this.setChevron(header, collapsed);
    });

    this.syncToggleAll();
  }

  syncToggleAll() {
    const allCollapsed = this.bodyTargets.every((body) =>
      body.classList.contains("hidden"),
    );
    this.toggleAllIconTarget.textContent = allCollapsed
      ? "unfold_more"
      : "unfold_less";
    this.toggleAllLabelTarget.textContent = allCollapsed
      ? "Expand all"
      : "Collapse all";
  }

  findBody(section) {
    return this.bodyTargets.find(
      (body) => body.dataset.collapsibleSectionsSection === section,
    );
  }

  findToggle(section) {
    return this.toggleTargets.find(
      (toggle) => toggle.dataset.collapsibleSectionsSection === section,
    );
  }

  setChevron(header, collapsed) {
    const chevron = header.querySelector("[data-collapsible-sections-chevron]");
    chevron?.classList.toggle("rotate-180", collapsed);
  }
}
