import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"] 

    connect() {
        const isCollapsed = localStorage.getItem("sidebar-collapsed") === "true"
        if (isCollapsed) this.collapse(false)
    }

    toggle() {
        if (this.containerTarget.classList.contains("w-0")) {
            this.expand()
        }
        else {
            this.collapse()
        }
    }

    collapse(animate = true) {
        if (animate) {
            this.containerTarget.classList.add("transition-all","duration-200")
        }
        this.containerTarget.classList.replace("w-64", "w-0")
        this.containerTarget.classList.replace("px-4", "px-0") // no padding so text doesn't bleed
        this.containerTarget.classList.add("overflow-hidden", "opacity-0")

        localStorage.setItem("sidebar-collapsed", "true")
    }

    expand() {
        this.containerTarget.classList.add("transition-all", "duration-300")

        // Switch back to expanded width
        this.containerTarget.classList.replace("w-0", "w-64")
        this.containerTarget.classList.replace("px-0", "px-4")
        this.containerTarget.classList.remove("overflow-hidden", "opacity-0")

        localStorage.setItem("sidebar-collapsed", "false")
    }
}
