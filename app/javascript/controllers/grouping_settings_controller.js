import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "groupingOptions", // the block shown when grouping_enabled = true
    "previewSection", // the preview block shown in prevent-leftover mode
    "optionalSuffix", // the "(optional)" label suffixes hidden in prevent-leftover mode
    "windowFields", // the end-date field
    "windowToggleBtn", // the "Set date / Remove date" button
    "previewInput", // the student count number input
    "minMax", // group_min and group_max inputs
  ];

  static values = {
    enabled: Boolean,
    finalised: Boolean,
  };

  connect() {
    this.applyEnabledState(this.enabledValue);
    this.applyFinalisedState(this.finalisedValue);
    this.applyWindowState();
  }

  // Called when the grouping_enabled switch changes.
  toggleEnabled(event) {
    this.applyEnabledState(event.target.checked);
  }

  // Called when the student_list_finalised switch changes.
  toggleMode(event) {
    this.applyFinalisedState(event.target.checked);
  }

  // Called by the "Set date / Remove date" button.
  toggleWindow(event) {
    event.preventDefault();
    const fields = this.windowFieldsTarget;
    const hidden = fields.classList.contains("hidden");
    fields.classList.toggle("hidden", !hidden);
    this.windowToggleBtnTarget.textContent = hidden
      ? "Remove date"
      : "Set date";

    // Clear the end date when the field is hidden so it is not submitted with a
    // stale value.
    if (!hidden) {
      fields
        .querySelectorAll("input[type='datetime-local']")
        .forEach((input) => {
          input.value = "";
        });
    }
  }

  // Called when group_min or group_max changes — clears the preview result so
  // stale numbers are not shown until the user triggers a new HTMX request.
  clearPreview() {
    const resultDiv = this.element.querySelector("#grouping_preview_result");
    if (resultDiv) resultDiv.innerHTML = "";
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  applyEnabledState(isEnabledNow) {
    if (!this.hasGroupingOptionsTarget) return;

    this.groupingOptionsTarget.classList.toggle("hidden", !isEnabledNow);
  }

  applyFinalisedState(finalised) {
    if (this.hasPreviewSectionTarget) {
      this.previewSectionTarget.classList.toggle("hidden", !finalised);
    }

    this.optionalSuffixTargets.forEach((suffix) => {
      suffix.classList.toggle("hidden", finalised);
    });
  }

  applyWindowState() {
    if (!this.hasWindowFieldsTarget) return;
    const hasValues = Array.from(
      this.windowFieldsTarget.querySelectorAll("input[type='datetime-local']"),
    ).some((input) => input.value.trim() !== "");

    this.windowFieldsTarget.classList.toggle("hidden", !hasValues);
    if (this.hasWindowToggleBtnTarget) {
      this.windowToggleBtnTarget.textContent = hasValues
        ? "Remove date"
        : "Set date";
    }
  }
}
