import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "confirm", "message"]

  validate() {
    const password = this.passwordTarget.value
    const confirm = this.confirmTarget.value
    
    if (confirm.length === 0) {
      this.messageTarget.textContent = ""
      this.messageTarget.classList.remove("text-red-600", "text-green-600")
      return
    }
    
    if (password === confirm) {
      this.messageTarget.textContent = "✓ Passwords match"
      this.messageTarget.classList.remove("text-red-600")
      this.messageTarget.classList.add("text-green-600", "text-sm", "mt-1")
    } else {
      this.messageTarget.textContent = "✗ Passwords do not match"
      this.messageTarget.classList.remove("text-green-600")
      this.messageTarget.classList.add("text-red-600", "text-sm", "mt-1")
    }
  }
}