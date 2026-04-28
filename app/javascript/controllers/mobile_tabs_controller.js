import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["btn", "detailsPanel", "progressPanel", "commentsPanel"];

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

    // 3. Hide all panels
    this.detailsPanelTarget.classList.add("hidden");
    this.detailsPanelTarget.classList.remove("block");
    this.commentsPanelTarget.classList.add("hidden");
    this.commentsPanelTarget.classList.remove("block");

    // Only hide progress panel if it exists on the page
    if (this.hasProgressPanelTarget) {
      this.progressPanelTarget.classList.add("hidden");
      this.progressPanelTarget.classList.remove("block");
    }

    // 4. Show the selected panel
    if (targetPanel === "details") {
      this.detailsPanelTarget.classList.remove("hidden");
      this.detailsPanelTarget.classList.add("block");
    } else if (targetPanel === "progress") {
      this.progressPanelTarget.classList.remove("hidden");
      this.progressPanelTarget.classList.add("block");
    } else if (targetPanel === "comments") {
      this.commentsPanelTarget.classList.remove("hidden");
      this.commentsPanelTarget.classList.add("block");
    }
  }
}
