import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lecturerPanel", "topicPanel", "hiddenLecturerId", "hiddenTopicId"]

  connect() {
    // Restore initial state from server-rendered hidden fields on page load
    const lecturerId = this.hiddenLecturerIdTarget.value
    const topicId = this.hiddenTopicIdTarget.value

    if (lecturerId) {
      this.#disablePanel(this.topicPanelTarget)
    } else if (topicId) {
      this.#disablePanel(this.lecturerPanelTarget)
    }
  }

  selectLecturer(event) {
    const button = event.currentTarget
    const lecturerId = button.dataset.lecturerId
    const isAlreadySelected = this.hiddenLecturerIdTarget.value === lecturerId

    if (isAlreadySelected) {
      // Deselect
      this.hiddenLecturerIdTarget.value = ""
      this.#markSelected(button, false)
      this.#enablePanel(this.topicPanelTarget)
    } else {
      // Warn if topic is already selected
      if (this.hiddenTopicIdTarget.value) {
        if (!confirm("You'll lose your selected topic. Continue?")) return
        this.hiddenTopicIdTarget.value = ""
      }

      this.hiddenLecturerIdTarget.value = lecturerId
      this.#clearAllLecturerSelections()
      this.#markSelected(button, true)
      this.#disablePanel(this.topicPanelTarget)
      this.#enablePanel(this.lecturerPanelTarget)
    }
  }

  // Called by the "Clear" link next to the lecturer heading
  clearLecturer(event) {
    event.preventDefault()
    this.hiddenLecturerIdTarget.value = ""
    this.#clearAllLecturerSelections()
    this.#enablePanel(this.topicPanelTarget)
  }

  // Private 

  #clearAllLecturerSelections() {
    this.lecturerPanelTarget
      .querySelectorAll("button[data-lecturer-id]")
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