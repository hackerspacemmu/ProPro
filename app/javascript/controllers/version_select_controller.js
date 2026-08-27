import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    course: Number,
    project: Number,
  }

  navigate(event) {
    const version = event.target.value
    const url = `/courses/${this.courseValue}/projects/${this.projectValue}?version=${version}`
    window.location.href = url
  }
}
