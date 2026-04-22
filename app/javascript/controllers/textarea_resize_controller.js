import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.resize();
  }

  resize() {
    // 1. Force the textarea to collapse completely
    this.element.style.height = "0px";

    // 2. The browser is now forced to calculate the EXACT height of the text content
    this.element.style.height = `${this.element.scrollHeight}px`;
  }

  commentResize() {
    this.resize();
  }

  resetComment(event) {
    if (event.target === this.element.form) {
      requestAnimationFrame(() => {
        this.element.value = "";
        this.resize();
      });
    }
  }
}
