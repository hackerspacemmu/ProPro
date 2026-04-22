import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["btn", "detailsPanel", "commentsPanel"];

  switchTab(event) {
    const clickedBtn = event.currentTarget;
    const targetPanel = clickedBtn.dataset.panel;

    // 1. Reset all buttons visually
    this.btnTargets.forEach((btn) => {
      btn.classList.remove("bg-slate-700", "text-white", "shadow-sm");
      btn.classList.add("text-gray-500");
    });

    // 2. Highlight clicked button
    clickedBtn.classList.remove("text-gray-500");
    clickedBtn.classList.add("bg-slate-700", "text-white", "shadow-sm");

    // 3. Toggle panels based on the dataset property
    if (targetPanel === "details") {
      this.detailsPanelTarget.classList.remove("hidden");
      this.detailsPanelTarget.classList.add("block");

      this.commentsPanelTarget.classList.remove("block");
      this.commentsPanelTarget.classList.add("hidden");
    } else {
      this.commentsPanelTarget.classList.remove("hidden");
      this.commentsPanelTarget.classList.add("block");

      this.detailsPanelTarget.classList.remove("block");
      this.detailsPanelTarget.classList.add("hidden");
    }
  }
}
