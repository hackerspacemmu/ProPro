import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="method-picker"
export default class extends Controller {
  static targets = [
    "basedOnTopic",
    "lecturerCard",
    "topicCard",
    "lecturerIndicator",
    "topicIndicator",
    "lecturerCheck",
    "topicCheck",
    "lecturerSurface",
    "lecturerEmpty",
    "topicSurface",
    "topicEmpty",
    "lecturerAvatar",
    "lecturerName",
    "lecturerCapacity",
    "topicName",
    "lecturerDialog",
    "topicDialog",
    "topicValues",
  ];

  connect() {
    this.boundCloseLecturerOnBackdrop = this.closeOnBackdrop.bind(
      this,
      "lecturerDialogTarget",
    );
    this.boundCloseTopicOnBackdrop = this.closeOnBackdrop.bind(
      this,
      "topicDialogTarget",
    );
    this.lecturerDialogTarget.addEventListener(
      "click",
      this.boundCloseLecturerOnBackdrop,
    );
    this.topicDialogTarget.addEventListener(
      "click",
      this.boundCloseTopicOnBackdrop,
    );
  }

  disconnect() {
    this.lecturerDialogTarget.removeEventListener(
      "click",
      this.boundCloseLecturerOnBackdrop,
    );
    this.topicDialogTarget.removeEventListener(
      "click",
      this.boundCloseTopicOnBackdrop,
    );
  }

  openLecturerPicker() {
    this.open(this.lecturerDialogTarget);
  }

  openTopicPicker() {
    this.open(this.topicDialogTarget);
  }

  open(dialog) {
    if (dialog.open) return;
    dialog.showModal();
  }

  closeLecturer() {
    this.lecturerDialogTarget.close();
  }

  closeTopic() {
    this.topicDialogTarget.close();
  }

  closeOnBackdrop(targetName, event) {
    if (event.target === this[targetName]) this[targetName].close();
  }

  chooseLecturer(event) {
    const option = event.currentTarget;
    this.applyThen(
      () => {
        this.basedOnTopicTarget.value = `own_proposal_${option.dataset.enrolmentId}`;
        this.activate("lecturer");
        this.clearFields();
      },
      () => {
        this.lecturerAvatarTarget.textContent = option.dataset.avatar;
        this.lecturerNameTarget.textContent = option.dataset.name;
        this.lecturerCapacityTarget.textContent = option.dataset.capacity;
      },
    );
    this.lecturerDialogTarget.close();
  }

  chooseTopic(event) {
    const option = event.currentTarget;
    this.applyThen(
      () => {
        this.basedOnTopicTarget.value = option.dataset.topicId;
        this.activate("topic");
        this.prefillFields(option.dataset.topicId);
      },
      () => {
        this.topicNameTarget.textContent = option.dataset.title;
      },
    );
    this.topicDialogTarget.close();
  }

  applyThen(fn, after) {
    const proceed =
      !this.contentPresent() ||
      window.confirm("You'll lose your current form data. Continue?");
    if (!proceed) return;
    fn();
    after();
  }

  contentPresent() {
    const form = this.basedOnTopicTarget.form;
    if (!form) return false;

    const fields = form.querySelectorAll("[name^='fields[']");
    for (const field of fields) {
      if (field.disabled || field.readOnly) continue;
      if (field.type === "radio" || field.type === "checkbox") {
        if (field.checked) return true;
      } else if ((field.value || "").trim() !== "") {
        return true;
      }
    }
    return false;
  }

  clearFields() {
    const form = this.basedOnTopicTarget.form;
    if (!form) return;

    form.querySelectorAll("[name^='fields[']").forEach((field) => {
      if (field.disabled) return;
      if (field.type === "radio" || field.type === "checkbox") {
        field.checked = false;
      } else {
        this.setFieldValue(field, "");
      }
    });
  }

  prefillFields(topicId) {
    const values = this.topicValueMap()[topicId] || {};
    const form = this.basedOnTopicTarget.form;
    if (!form) return;

    for (const [fieldId, value] of Object.entries(values)) {
      const field = form.querySelector(`[name="fields[${fieldId}]"]`);
      if (!field || field.disabled) continue;

      if (field.type === "radio") {
        form
          .querySelectorAll(`[name="fields[${fieldId}]"]`)
          .forEach((radio) => {
            radio.checked = radio.value === value;
          });
      } else {
        this.setFieldValue(field, value);
      }
    }
  }

  topicValueMap() {
    try {
      return JSON.parse(this.topicValuesTarget.textContent || "{}");
    } catch {
      return {};
    }
  }

  setFieldValue(field, value) {
    field.value = value;
    field.dispatchEvent(new Event("change", { bubbles: true }));
    field.dispatchEvent(
      new CustomEvent("text-editor:update", {
        detail: { value },
        bubbles: true,
      }),
    );
  }

  activate(method) {
    const lecturerActive = method === "lecturer";

    if (this.hasLecturerCardTarget) {
      this.setCardActive(this.lecturerCardTarget, lecturerActive);
    }
    if (this.hasTopicCardTarget) {
      this.setCardActive(this.topicCardTarget, !lecturerActive);
    }
    if (this.hasLecturerIndicatorTarget) {
      this.setIndicator(
        this.lecturerIndicatorTarget,
        this.lecturerCheckTarget,
        lecturerActive,
      );
    }
    if (this.hasTopicIndicatorTarget) {
      this.setIndicator(
        this.topicIndicatorTarget,
        this.topicCheckTarget,
        !lecturerActive,
      );
    }
    if (this.hasLecturerSurfaceTarget && this.hasLecturerEmptyTarget) {
      this.lecturerSurfaceTarget.classList.toggle("hidden", !lecturerActive);
      this.lecturerEmptyTarget.classList.toggle("hidden", lecturerActive);
    }
    if (this.hasTopicSurfaceTarget && this.hasTopicEmptyTarget) {
      this.topicSurfaceTarget.classList.toggle("hidden", lecturerActive);
      this.topicEmptyTarget.classList.toggle("hidden", !lecturerActive);
    }
  }

  setCardActive(card, active) {
    const addClasses = active
      ? card.dataset.activeClasses.split(" ")
      : card.dataset.inactiveClasses.split(" ");
    const removeClasses = active
      ? card.dataset.inactiveClasses.split(" ")
      : card.dataset.activeClasses.split(" ");

    removeClasses.forEach((className) => card.classList.remove(className));
    addClasses.forEach((className) => card.classList.add(className));
  }

  setIndicator(indicator, check, active) {
    indicator.classList.toggle("bg-[#1A73E8]", active);
    indicator.classList.toggle("text-white", active);
    indicator.classList.toggle("border", !active);
    indicator.classList.toggle("border-[#DADCE0]", !active);
    check.classList.toggle("hidden", !active);
  }
}
