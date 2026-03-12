/* global Turbo */
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { targetCourseId: String, mode: String };
  static targets = ["preview", "label", "value", "menu", "container", "content"]

  connect() {
    this.courseList= null;
  }

  // Open the overlay
  open(e) {
    e.preventDefault();
    if (!this.courseList) {
      this.courseList = this.containerTarget.innerHTML;
    }

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

    setTimeout(() => {
      if (this.courseList) this.containerTarget.innerHTML = this.courseList;
    }, 200);
  }

  // Close when clicking outsite of the ovelay
  closeOnBackdrop(e) {
    if (e.target === this.menuTarget) {
      this.close();
    }
  }

  goBack(event) {
    if (event) event.preventDefault();
    if (this.courseList) {
      this.containerTarget.innerHTML = this.courseList;
    }
  }

  selectSetting(event) {
    const sourceCourseId = event.params.courseId;
    const targetCourseId = this.targetCourseIdValue
    const mode = this.modeValue;

    this.containerTarget.src = `/courses/${targetCourseId}/details?source_id=${sourceCourseId}&mode=${mode}`;
  }

  selectTopic(event) {
    const sourceTopicId = event.params.courseId;
    const targetCourseId = this.targetCourseIdValue;

    this.containerTarget.src = `/courses/${targetCourseId}/topics/new?source_topic_id=${sourceTopicId}`;
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

  copyTopicsDetails() {
    const selects = this.element.querySelectorAll('select[data-target-field-id]')

    selects.forEach(select => {
      const targetId = select.dataset.targetFieldId
      const selectedOption = select.options[select.selectedIndex]
      
      if (!selectedOption || selectedOption.value === "") return // Skip if 'Keep Empty'

      const newValue = selectedOption.dataset.value
      const mainInput = document.getElementById(targetId)

      if (mainInput) {
        if (mainInput.type === 'radio' || mainInput.tagName === 'FIELDSET') {
          const name = mainInput.name || `fields[${targetId.split('_')[1]}]`
          const radioToSelect = document.querySelector(`input[name="${name}"][value="${newValue}"]`)
          if (radioToSelect) radioToSelect.checked = true
        } 
        else if (mainInput.tagName === 'SELECT') {
          mainInput.value = newValue
          mainInput.dispatchEvent(new Event('change', { bubbles: true }))
        }
        else {
          mainInput.value = newValue
          mainInput.dispatchEvent(new Event('input', { bubbles: true }))
        }
      }
    })

    this.close();
  }
}
