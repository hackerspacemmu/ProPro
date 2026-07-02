import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { targetCourseId: String, mode: String };
  static targets = [
    "preview",
    "label",
    "value",
    "menu",
    "container",
    "content",
  ];

  connect() {
    this.initialContent = this.containerTarget.innerHTML;
  }

  disconnect() {
    document.body.style.overflow = "";
  }

  // Open the overlay
  open(e) {
    if (e) e.preventDefault();

    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("opacity-0", "pointer-events-none");
    }
    if (this.hasContentTarget) {
      this.contentTarget.classList.remove("translate-y-full");
    }
    document.body.style.overflow = "hidden";
  }

  // Close the overlay
  close(e) {
    if (e) e.preventDefault();

    document.body.style.overflow = "";
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("opacity-0", "pointer-events-none");
    }
    if (this.hasContentTarget) {
      this.contentTarget.classList.add("translate-y-full");
    }

    setTimeout(() => {
      this.returnToList();
    }, 200);
  }

  // Close when clicking outsite of the ovelay
  closeOnBackdrop(e) {
    if (e.target === this.menuTarget) {
      this.close(e);
    }
  }

  returnToList() {
    this.containerTarget.removeAttribute("src");
    this.containerTarget.removeAttribute("complete");

    if (this.initialContent) {
      this.containerTarget.innerHTML = this.initialContent;
    } else {
      this.containerTarget.innerHTML = "";
    }
  }

  selectSetting(event) {
    const sourceCourseId = event.params.sourceId; 
    const targetCourseId = this.targetCourseIdValue;
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

    const row = select.closest(".field-row");
    if (!row) return;

    // Filter targets to find the ones specifically inside this row
    const preview = this.previewTargets.find((el) => row.contains(el));
    const label = this.labelTargets.find((el) => row.contains(el));
    const value = this.valueTargets.find((el) => row.contains(el));

    if (!option || !option.value) {
      if (preview) preview.classList.add("hidden");
      return;
    }

    if (label) label.textContent = option.dataset.label;
    if (value) value.textContent = option.dataset.value || "No value provided";
    if (preview) preview.classList.remove("hidden");
  }

  copyTopicsDetails(event) {
    const overlaySourceInput = this.element.querySelector("#overlay_source_topic_id");
    const mainSourceInput = document.querySelector("#main_source_topic_id");

    if (overlaySourceInput && mainSourceInput) {
      mainSourceInput.value = overlaySourceInput.value;
    }

    const selects = this.element.querySelectorAll("select[data-target-field-id]");
    const mainForm = document.querySelector("form[action*='/topics']");

    selects.forEach((select) => {
      const targetId = select.dataset.targetFieldId;
      const selectedOption = select.options[select.selectedIndex];
      const sourceFieldId = selectedOption ? selectedOption.value : "";
      const newValue = (selectedOption && sourceFieldId !== "") ? selectedOption.dataset.value : "";
      
      const fieldId = targetId.replace("fields_", "");
      const fieldName = `fields[${fieldId}]`;

      const existingHidden = mainForm.querySelector(`input[name="source_fields[${fieldId}]"]`);
      if (existingHidden) existingHidden.remove();

      if (sourceFieldId !== "") {
        const hiddenInput = document.createElement("input");
        hiddenInput.type = "hidden";
        hiddenInput.name = `source_fields[${fieldId}]`;
        hiddenInput.value = sourceFieldId;
        mainForm.appendChild(hiddenInput);
      }
      
      const mainInputs = document.querySelectorAll(`[name="${fieldName}"]`);

      mainInputs.forEach((mainInput) => {
        if (mainInput.type === "radio") {
          if (newValue === "") {
            mainInput.checked = false;
          } else {
            mainInput.checked = (mainInput.value === newValue);
          }
        } else if (mainInput.tagName === "SELECT") {
          mainInput.value = newValue;
          mainInput.dispatchEvent(new Event("change", { bubbles: true }));
        } else {
          mainInput.value = newValue;
          mainInput.dispatchEvent(new Event("input", { bubbles: true }));
          mainInput.dispatchEvent(new CustomEvent("text-editor:update", { detail: { value: newValue }}));
        }
      });
    });

    this.close(event);
  }
}
