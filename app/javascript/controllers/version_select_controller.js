import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  navigate(event) {
    const version = event.target.value;
    window.location.href = `${window.location.pathname}?version=${version}`;
  }
}
