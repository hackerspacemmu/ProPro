import { Controller } from "@hotwired/stimulus";

// Single-select row behavior for the Students table plus the Actions
// dropdown dispatch (Email / Remove on the one selected row).
//
// The table body is swapped by htmx for search/sort/pagination, so this
// controller deliberately uses delegated listeners + a plain htmx:afterSwap
// reset instead of row targets — selection state only lives in the swapped
// region and intentionally resets when the table re-renders.
export default class extends Controller {
  static targets = ["actions", "emailItem"];

  connect() {
    this.onChange = this.onChange.bind(this);
    this.onSwap = this.onSwap.bind(this);
    this.element.addEventListener("change", this.onChange);
    this.element.addEventListener("htmx:afterSwap", this.onSwap);
    this.refresh();
  }

  disconnect() {
    this.element.removeEventListener("change", this.onChange);
    this.element.removeEventListener("htmx:afterSwap", this.onSwap);
  }

  selectedRow() {
    const radio = this.element.querySelector(
      'input[name="students_table_selection"]:checked',
    );
    return radio ? radio.closest("tr") : null;
  }

  onChange(event) {
    if (event.target.type !== "checkbox") return;
    if (event.target.name !== "students_table_selection") return;

    // Material checkbox but single-select semantics: checking one clears any
    // other checked row, so the Actions dropdown always operates on one row.
    if (event.target.checked) {
      this.element
        .querySelectorAll('input[name="students_table_selection"]:checked')
        .forEach((checkbox) => {
          if (checkbox !== event.target) checkbox.checked = false;
        });
    }
    this.refresh();
  }

  onSwap() {
    this.refresh();
  }

  refresh() {
    // The whole Actions control only exists for student managers; students and
    // lecturers get a read-only table with no such targets.
    if (!this.hasActionsTarget) return;

    const row = this.selectedRow();
    const actions = this.actionsTarget;
    if (row) {
      actions.removeAttribute("disabled");
      // The email action only makes sense for students who haven't activated
      // their account — it resends the ProPro invite via GeneralMailer
      // (main-branch semantics), so hide it for registered students.
      this.emailItemTarget.classList.toggle(
        "hidden",
        row.dataset.studentInvited !== "true",
      );
    } else {
      actions.setAttribute("disabled", "");
      this.emailItemTarget.classList.add("hidden");
    }
  }

  email(event) {
    event.preventDefault();
    const row = this.selectedRow();
    if (!row) return;

    this.submitForm(row.dataset.resendUrl);
  }

  remove(event) {
    event.preventDefault();
    const row = this.selectedRow();
    if (!row) return;

    const message =
      "Are you sure?\nThe user will be removed from the COURSE.\n" +
      "Their associated PROJECT HISTORY and COMMENTS will be DELETED if they're the last member.";
    if (!window.confirm(message)) return;

    this.submitForm(row.dataset.removeUrl, "delete");
  }

  submitForm(url, method = "post") {
    const token = document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute("content");
    const form = document.createElement("form");
    form.method = "post";
    form.action = url;

    if (token) {
      const csrf = document.createElement("input");
      csrf.type = "hidden";
      csrf.name = "authenticity_token";
      csrf.value = token;
      form.appendChild(csrf);
    }

    if (method !== "post") {
      const methodField = document.createElement("input");
      methodField.type = "hidden";
      methodField.name = "_method";
      methodField.value = method;
      form.appendChild(methodField);
    }

    document.body.appendChild(form);
    form.submit();
  }
}