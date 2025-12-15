import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"] 

    connect() {
        const isMobile = window.innerWidth < 950 

        if (isMobile) {
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
        
        this.containerTarget.classList.replace("px-0", "px-4")

        localStorage.setItem("sidebar-collapsed", "false")
    }
}
