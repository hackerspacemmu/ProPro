import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"]

    connect() {
        this.checkResponsive()
        this.resizeHandler = this.checkResponsive.bind(this)
        window.addEventListener("resize", this.resizeHandler)
    }

    disconnect() {
        window.removeEventListener("resize", this.resizeHandler)
    }

    checkResponsive() {
        const isDesktop = window.innerWidth >= 1024

        if (isDesktop) {
            if (!this.containerTarget.classList.contains("lg:w-64")) {
                this.resetToDesktopDefaults()
            }
        } else {
            const userPreferClosed = localStorage.getItem("sidebar-collapsed") === "true"
            if (userPreferClosed) {
                this.collapse(false)
            }
        }
    }

    toggle() {
        if (this.containerTarget.clientWidth === 0) {
            this.expand()
        } else {
            this.collapse()
        }
    }

    collapse(animate = true) {
        if (animate) {
            this.containerTarget.classList.add("transition-all", "duration-200")
        }
        this.containerTarget.classList.remove("lg:w-64", "lg:opacity-100")
        this.containerTarget.classList.remove("w-64") 
        this.containerTarget.classList.add("w-0")

        this.containerTarget.classList.replace("px-4", "px-0")
        this.containerTarget.classList.add("overflow-hidden", "opacity-0")

        localStorage.setItem("sidebar-collapsed", "true")
    }

    expand() {
        this.containerTarget.classList.add("transition-all", "duration-300")

        this.containerTarget.classList.remove("w-0", "overflow-hidden", "opacity-0")
        this.containerTarget.classList.add("w-64", "opacity-100") 

        if (window.innerWidth >= 1024) {
             this.containerTarget.classList.add("lg:w-64", "lg:opacity-100")
        }

        this.containerTarget.classList.replace("px-0", "px-4")

        localStorage.setItem("sidebar-collapsed", "false")
    }

    resetToDesktopDefaults() {
        this.containerTarget.classList.remove("w-0", "overflow-hidden", "opacity-0")
        this.containerTarget.classList.add("lg:w-64", "lg:opacity-100", "w-64", "opacity-100")
        this.containerTarget.classList.replace("px-0", "px-4")
    }
}
