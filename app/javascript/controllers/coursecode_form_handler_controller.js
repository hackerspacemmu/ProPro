import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="coursecode-form-handler"
export default class extends Controller {
  static targets = ["generateFlag"];

  submitForm() {
    this.element.requestSubmit();
  }

  generateCode(event) {
    event.preventDefault();
    this.generateFlagTarget.value = "true";
    this.element.requestSubmit();
  }
}
