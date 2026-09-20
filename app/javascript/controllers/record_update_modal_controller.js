import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "dialog",
    "editDialog",
    "editForm",
    "editRating",
    "editFeedback",
    "editDate",
  ];

  connect() {
    this.boundCloseOnBackdrop = this.closeOnBackdrop.bind(this);
    this.dialogTarget.addEventListener("click", this.boundCloseOnBackdrop);
    this.editDialogTarget.addEventListener("click", this.boundCloseOnBackdrop);
  }

  disconnect() {
    this.dialogTarget.removeEventListener("click", this.boundCloseOnBackdrop);
    this.editDialogTarget.removeEventListener(
      "click",
      this.boundCloseOnBackdrop,
    );
  }

  open() {
    this.dialogTarget.showModal();
  }

  openEdit(event) {
    const { rating, feedback, date, updateUrl } = event.currentTarget.dataset;
    this.editRatingTarget.value = rating || "";
    this.editFeedbackTarget.value = feedback || "";
    this.editDateTarget.value = date || "";
    this.editFormTarget.action = updateUrl;
    this.editDialogTarget.showModal();
  }

  close(event) {
    const dialog = event.currentTarget.closest("dialog");
    if (dialog) dialog.close();
  }

  closeOnBackdrop(event) {
    if (event.target.matches("dialog")) event.target.close();
  }
}