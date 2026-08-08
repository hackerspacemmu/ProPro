import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="field-expand-modal"
export default class extends Controller {
  static targets = ["dialog", "title", "content"];

  connect() {
    this.boundCloseOnBackdrop = this.closeOnBackdrop.bind(this);
    this.dialogTarget.addEventListener("click", this.boundCloseOnBackdrop);
  }

  disconnect() {
    this.dialogTarget.removeEventListener("click", this.boundCloseOnBackdrop);
  }

  open(event) {
    const button = event.currentTarget;
    const template = button.querySelector("template");
    if (!template) return;

    const title = button.dataset.title || "";
    this.titleTarget.textContent = title;
    // Set directly rather than aria-labelledby+id — this partial renders
    // twice per page (mobile + desktop copies), so a static id would collide.
    this.dialogTarget.setAttribute("aria-label", title);

    this.contentTarget.innerHTML = "";
    this.contentTarget.appendChild(template.content.cloneNode(true));
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close();
  }
}