import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = [ "list" ]

  connect() {
    this.sortable = Sortable.create(this.element, {
      draggable: ".field-row",
      handle: ".cursor-grab",
      animation: 150,
      ghostClass: "opacity-25",
      chosenClass: "sortable-chosen",
      dragClass: "sortable-drag",
      forceFallback: true,
      onEnd: this.updatePositions.bind(this)
    })
  }

    updatePositions() {
    const rows = this.element.querySelectorAll(".field-row")
    
    rows.forEach((row, index) => {
        const positionInput = row.querySelector(".position-input")
        if (positionInput) {
        positionInput.value = index + 1

        positionInput.dispatchEvent(new Event("change", { bubbles: true }))
        }
    })
    }
}
