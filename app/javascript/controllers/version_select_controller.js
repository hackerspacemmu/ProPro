import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    course: Number,
    resourceId: Number,
    resource: { type: String, default: "projects" },
  };

  navigate(event) {
    const version = event.target.value;
    const resource = this.resourceValue;
    const id = this.resourceIdValue;
    const url = `/courses/${this.courseValue}/${resource}/${id}?version=${version}`;
    window.location.href = url;
  }
}
