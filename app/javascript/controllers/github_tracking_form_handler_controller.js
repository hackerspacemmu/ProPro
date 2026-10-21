import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="github-tracking-form-handler"
// Formless github tracking widget (ADR-0010): no <form> in the static
// DOM, so it can live inside #course-settings-form without nesting one. The
// toggle and the domain submit each fetch() the update_github_tracking endpoint
// with a form-encoded body, then render its turbo stream (replaces the
// github_tracking_form frame and the flash).
export default class extends Controller {
  static targets = ["enabledToggle", "domainInput"];
  static values = { url: String };


  connect() {
    console.log("GitHub tracking controller connected successfully!");
  }

  async post(body) {
    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/x-www-form-urlencoded", // <-- Crucial so Rails parses params[:course] correctly
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          ?.content,
      },
      body,
    });

    if (response.ok) {
      window.Turbo.renderStreamMessage(await response.text());
    } else {
      console.error("Failed to update GitHub tracking", await response.text());
    }
  }

  async toggle(event) {
    await this.post(
      new URLSearchParams({
        "course[github_tracking_enabled]": event.target.checked
          ? "1"
          : "0",
      }),
    );
  }

  async submitDomain() {
    await this.post(
      new URLSearchParams({
        "course[github_tracking_enabled]": this.enabledToggleTarget
          .checked
          ? "1"
          : "0",
      }),
    );
  }
}