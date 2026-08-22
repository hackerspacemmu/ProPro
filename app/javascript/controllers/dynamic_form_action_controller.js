import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    baseUrl: String,
    endpoint: String,
  };

  update(event) {
    const targetId = event.target.value;

    if (targetId) {
      this.element.action = `${this.baseUrlValue}/${targetId}/${this.endpointValue}`;
    }
  }
}
