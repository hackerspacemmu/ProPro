import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "groupingOptions", // the block shown when grouping_enabled = true
    "previewSection", // the preview block shown in student_list_finalised mode
    "windowFields", // the open/close datetime fields
    "windowToggleBtn", // the "Set a window / Remove window" button
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

  // Called when the grouping_enabled radio buttons change.
  toggleEnabled(event) {
    const enabled = event.target.value === "true";
    this.applyEnabledState(enabled);
  }

  // Called when the student_list_finalised radio buttons change.
  toggleMode(event) {
    const finalised = event.target.value === "true";
    this.applyFinalisedState(finalised);
  }

  // Called by the "Set a window / Remove window" button.
  toggleWindow(event) {
    event.preventDefault();
    const fields = this.windowFieldsTarget;
    const hidden = fields.classList.contains("hidden");
    fields.classList.toggle("hidden", !hidden);
    this.windowToggleBtnTarget.textContent = hidden
      ? "Remove window"
      : "Set a window";

    // Clear the datetime fields when the window is hidden so they are not
    // submitted with stale values.
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

  applyEnabledState(enabled) {
    if (!this.hasGroupingOptionsTarget) return;
    this.groupingOptionsTarget.classList.toggle("hidden", !enabled);
  }

  applyFinalisedState(finalised) {
    if (!this.hasPreviewSectionTarget) return;
    this.previewSectionTarget.classList.toggle("hidden", !finalised);
  }

  applyWindowState() {
    if (!this.hasWindowFieldsTarget) return;
    const hasValues = Array.from(
      this.windowFieldsTarget.querySelectorAll("input[type='datetime-local']"),
    ).some((input) => input.value.trim() !== "");

    this.windowFieldsTarget.classList.toggle("hidden", !hasValues);
    if (this.hasWindowToggleBtnTarget) {
      this.windowToggleBtnTarget.textContent = hasValues
        ? "Remove window"
        : "Set a window";
    }
  }
}
