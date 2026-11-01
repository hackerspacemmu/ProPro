import { Controller } from "@hotwired/stimulus";

// One shared confirmation dialog for every destructive form on the page.
// Forms opt in with data-confirm-submit (plus data-confirm-title/body/ok/danger);
// this controller intercepts their submit in the capture phase, fills the dialog,
// and only re-submits after the user confirms.
//
// data-confirm-body may hold several paragraphs separated by a blank line
// ("A.\n\nB."). They are rendered as <p> children via textContent, so it stays XSS-safe.
export default class extends Controller {
  static targets = ["title", "body", "ok"];

  connect() {
    this.onSubmit = this.onSubmit.bind(this);
    this.pendingForm = null;
    this.submitting = false;
    document.addEventListener("submit", this.onSubmit, true);
  }

  disconnect() {
    document.removeEventListener("submit", this.onSubmit, true);
  }

  onSubmit(event) {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;
    if (!form.hasAttribute("data-confirm-submit")) return;

    if (form.dataset.confirmConfirmed === "true") {
      delete form.dataset.confirmConfirmed;
      return;
    }

    event.preventDefault();
    this.pendingForm = form;

    const title = form.dataset.confirmTitle || "Are you sure?";
    const body = form.dataset.confirmBody || "";
    const okLabel = form.dataset.confirmOk || "Confirm";
    const danger = form.dataset.confirmDanger === "true";

    this.titleTarget.textContent = title;
    this.bodyTarget.replaceChildren(
      ...body.split("\n\n").filter(Boolean).map((text) => {
        const p = document.createElement("p");
        p.textContent = text;
        return p;
      }),
    );
    this.bodyTarget.classList.toggle("hidden", body.length === 0);
    this.okTarget.textContent = okLabel;
    this.okTarget.classList.toggle("bg-error", danger);
    this.okTarget.classList.toggle("hover:bg-error-hover", danger);
    this.okTarget.classList.toggle("bg-primary-strong", !danger);
    this.okTarget.classList.toggle("hover:bg-primary-hover", !danger);

    this.element.showModal();
  }

  confirm() {
    const form = this.pendingForm;
    if (!form) return;

    this.pendingForm = null;
    this.submitting = true;
    form.dataset.confirmConfirmed = "true";
    this.element.close();
    form.requestSubmit();
    this.submitting = false;
  }

  cancel() {
    this.pendingForm = null;
    this.element.close();
  }
}
