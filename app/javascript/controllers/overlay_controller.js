/* global Turbo */
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { targetCourseId: String, mode: String };
  static targets = ["preview", "label", "value", "menu", "container", "content"]

  connect() {
    this.initializeSelects();

    this.element.addEventListener("turbo:frame-render", () => {
      this.initializeSelects();
    });
  }

  initializeSelects() {
    this.element.querySelectorAll('select').forEach(select => {
      // Only trigger if a value is selected
      if (select.value && select.value !== "") {
        this.updateDropdown({ target: select });
      }
    });
  }

  // Open the overlay
  open(e) {
    e.preventDefault();
    this.menuTarget.classList.remove("opacity-0", "pointer-events-none");
    this.contentTarget.classList.remove("translate-y-full");
    document.body.classList.add("overflow-hidden");
  }

  // Close the overlay
  close(e) {
    if (e) e.preventDefault();
    this.menuTarget.classList.add("opacity-0", "pointer-events-none");
    this.contentTarget.classList.add("translate-y-full");
    document.body.classList.remove("overflow-hidden");
  }

  // Close when clicking outsite of the ovelay
  closeOnBackdrop(e) {
    if (e.target === this.menuTarget) {
      this.close();
    }
  }

  selectSetting(event) {
    const sourceCourseId = event.params.courseId;
    const targetCourseId = this.targetCourseIdValue
    const mode = this.modeValue;
    const frame = document.getElementById("overlay_content");

    frame.src = `/courses/${targetCourseId}/details?source_id=${sourceCourseId}&mode=${mode}`;
  }

  selectTopic(event) {
    const sourceTopicId = event.params.courseId;
    const targetCourseId = this.targetCourseIdValue;
    const frame = document.getElementById("overlay_content");

    frame.src = `/courses/${targetCourseId}/topics/new?source_topic_id=${sourceTopicId}`;
  }

  updateDropdown(event) {
    const select = event.target;
    const option = select.options[select.selectedIndex];
    
    const row = select.closest('.field-row');
    if (!row) return;

    // Filter targets to find the ones specifically inside this row
    const preview = this.previewTargets.find(el => row.contains(el));
    const label = this.labelTargets.find(el => row.contains(el));
    const value = this.valueTargets.find(el => row.contains(el));

    if (!option || !option.value) {
      if (preview) preview.classList.add('hidden');
      return;
    }

    if (label) label.textContent = option.dataset.label;
    if (value) value.textContent = option.dataset.value || "No value provided";
    if (preview) preview.classList.remove('hidden');
  }
}
