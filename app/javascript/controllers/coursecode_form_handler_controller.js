import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="coursecode-form-handler"
// Fires the coursecode_enabled toggle independently of any <form>: fetch() the
// update_coursecode endpoint with a form-encoded body, then render its turbo
// stream (replaces the course_code_form frame and the flash).
export default class extends Controller {
  static values = { url: String };

  async toggle(event) {
    const body = new URLSearchParams({
      "course[coursecode_enabled]": event.target.checked ? "1" : "0"
    });

    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body
    });

    if (response.ok) {
      window.Turbo.renderStreamMessage(await response.text());
    }
  }
}