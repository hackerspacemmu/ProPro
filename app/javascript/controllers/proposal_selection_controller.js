import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lecturerPanel", "topicPanel", "hiddenBasedOnTopic"]

  connect() {
    // Restore initial state from server-rendered hidden fields on page load
    const basedOnTopic = this.hiddenBasedOnTopicTarget.value
    if (basedOnTopic.startsWith('own_proposal_')) {
      this.#disablePanel(this.topicPanelTarget)
    } else if (basedOnTopic) {
      this.#disablePanel(this.lecturerPanelTarget)
    }
  }

  selectLecturer(event) {
    const button = event.currentTarget
    const enrolmentId = button.dataset.enrolmentId
    const isAlreadySelected = this.hiddenBasedOnTopicTarget.value === `own_proposal_${enrolmentId}`

    if (isAlreadySelected) {
      // Deselect
      this.hiddenBasedOnTopicTarget.value = ""
      this.#markSelected(button, false)
      this.#enablePanel(this.topicPanelTarget)
    } else {
      // Warn if topic is already selected
      if (this.hiddenBasedOnTopicTarget.value && !this.hiddenBasedOnTopicTarget.value.startsWith('own_proposal_')) {
        if (!confirm("You'll lose your selected topic. Continue?")) return
      }

      this.hiddenBasedOnTopicTarget.value = `own_proposal_${enrolmentId}`
      this.#clearAllLecturerSelections()
      this.#markSelected(button, true)
      this.#disablePanel(this.topicPanelTarget)
      this.#enablePanel(this.lecturerPanelTarget)
    }
  }

  // Called by the "Clear" link next to the lecturer heading
  clearLecturer(event) {
    event.preventDefault()
    this.hiddenBasedOnTopicTarget.value = ""
    this.#clearAllLecturerSelections()
    this.#enablePanel(this.topicPanelTarget)
  }

  // Private 

  #clearAllLecturerSelections() {
    this.lecturerPanelTarget
      .querySelectorAll("button[data-enrolment-id]")
      .forEach(btn => this.#markSelected(btn, false))
  }

  #markSelected(button, selected) {
    const check = button.querySelector("[data-selected-check]")

    if (selected) {
      button.classList.add("border-blue-400", "ring-2", "ring-blue-100")
      button.classList.remove("border-gray-200", "hover:border-gray-400")
      if (check) check.classList.remove("hidden")
    } else {
      button.classList.remove("border-blue-400", "ring-2", "ring-blue-100")
      button.classList.add("border-gray-200", "hover:border-gray-400")
      if (check) check.classList.add("hidden")
    }
  }

  #disablePanel(panel) {
    panel.classList.add("opacity-50", "pointer-events-none")
  }

  #enablePanel(panel) {
    panel.classList.remove("opacity-50", "pointer-events-none")
  }
}