import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    requestAnimationFrame(() => {
      this.resize();
    });
  }

  resize() {
    if (this.element.offsetParent === null) return;

    this.element.style.height = "auto";
    this.element.style.height = `${this.element.scrollHeight}px`;
  }

  commentResize() {
    this.resize();
  }

  resetComment(event) {
    if (event.target === this.element.form) {
      requestAnimationFrame(() => {
        this.element.value = "";
        this.element.style.height = "auto";
      });
    }
  }
}
