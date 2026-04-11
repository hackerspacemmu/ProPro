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

  commentResize() {
    this.element.style.height = "auto";
    this.element.style.height = `${this.element.scrollHeight + 2}px`;
  }

  resetComment(event) {
    if (event.target === this.element.form) {
      requestAnimationFrame(() => {
        this.element.value = "";
        this.element.style.height = "auto";
        this.element.style.height = `${this.element.scrollHeight + 2}px`;
      });
    }
  }
}
