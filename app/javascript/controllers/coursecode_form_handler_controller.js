import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="coursecode-form-handler"
// Formless coursecode widget (ADR-0010): no <form> in the static DOM, so it can
// live inside #course-settings-form without nesting one. Generate/toggle fetch()
// the update_coursecode endpoint with a form-encoded body, then render its
// turbo stream (replaces the course_code_form frame and the flash). Copy writes
// the current join code to the clipboard.
export default class extends Controller {
  static targets = ["codeInput", "copyIcon"];
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

  generate() {
    return this.post(new URLSearchParams({ generate: "true" }));
  }

  toggle(event) {
    return this.post(
      new URLSearchParams({
        "course[coursecode_enabled]": event.target.value === "true" ? "1" : "0",
      }),
    );
  }

  async copy() {
    const code = this.codeInputTarget.value;
    if (!code) return;

    try {
      await navigator.clipboard.writeText(code);
      this.flashCopied();
    } catch {
      // Clipboard unavailable (insecure context / permission) — no-op.
    }
  }

  flashCopied() {
    if (!this.hasCopyIconTarget) return;

    const icon = this.copyIconTarget;
    icon.textContent = "check";
    clearTimeout(this.copyResetTimer);
    this.copyResetTimer = setTimeout(() => {
      icon.textContent = "content_copy";
    }, 1500);
  }
}
