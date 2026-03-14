import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="textarea-resize"
export default class extends Controller {
  connect() {
    this.resize();
  }

  resize() {
    this.element.style.height = "auto";
    this.element.style.height = `${this.element.scrollHeight + 2}px`;
  }
}
