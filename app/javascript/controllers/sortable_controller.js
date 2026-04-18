import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = [ "list" ]

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: ".cursor-grab",
      animation: 150,
      ghostClass: "bg-blue-50",
      onEnd: this.onEnd.bind(this)
    })
  }

  onEnd(event) {
    const id = event.item.dataset.id
    const newPosition = event.newIndex + 1 // acts_as_list uses 1-based indexing

    // If there's no ID (e.g., a newly added row not yet saved), skip
    if (!id) return 

    fetch(`/project_template_fields/${id}/move`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({
        project_template_field: { position: newPosition }
      })
    })
    .then(response => {
      if (!response.ok) {
        console.error("Failed to save new position")
        // Optionally revert the UI if the server rejects the change
        // window.location.reload()
      }
    })
  }
}
