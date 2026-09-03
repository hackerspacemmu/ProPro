import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    course: Number,
    project: Number,
    topic: Number,
  };

  navigate(event) {
    const version = event.target.value;
    window.location.href = `${this.baseUrl}?version=${version}`;
  }

  get baseUrl() {
    if (this.hasProjectValue) {
      return `/courses/${this.courseValue}/projects/${this.projectValue}`;
    }
    if (this.hasTopicValue) {
      return `/courses/${this.courseValue}/topics/${this.topicValue}`;
    }
    return "/";
  }
}
