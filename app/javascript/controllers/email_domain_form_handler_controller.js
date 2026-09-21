import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="email-domain-form-handler"
// Formless email-domain restriction widget (ADR-0010): no <form> in the static
// DOM, so it can live inside #course-settings-form without nesting one. The
// toggle and the domain submit each fetch() the update_email_domain endpoint
// with a form-encoded body, then render its turbo stream (replaces the
// email_domain_restrict_form frame and the flash).
export default class extends Controller {
  static targets = ["enabledToggle", "domainInput"];
  static values = { url: String };

  async post(body) {
    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          ?.content,
      },
      body,
    });

    if (response.ok) {
      window.Turbo.renderStreamMessage(await response.text());
    }
  }

  async toggle(event) {
    await this.post(
      new URLSearchParams({
        "course[email_domain_restriction_enabled]": event.target.checked
          ? "1"
          : "0",
        "course[email_domain_restriction]": this.domainInputTarget.value,
      }),
    );
  }

  async submitDomain() {
    await this.post(
      new URLSearchParams({
        "course[email_domain_restriction_enabled]": this.enabledToggleTarget
          .checked
          ? "1"
          : "0",
        "course[email_domain_restriction]": this.domainInputTarget.value,
      }),
    );
  }
}
