import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 },
    persistent: { type: Boolean, default: false }
  }

  connect() {
    if (this.persistentValue) return
    this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)
    this.element.classList.add("opacity-0")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
    // Fallback in case no transition fires (reduced motion, or transition classes unavailable)
    setTimeout(() => this.element.remove(), 300)
  }
}