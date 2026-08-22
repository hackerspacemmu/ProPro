import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "groupingOptions", // the block shown when grouping_enabled = true
    "previewSection", // the preview block shown in student_list_finalised mode
    "windowFields", // the open/close datetime fields
    "windowToggleBtn", // the "Set a window / Remove window" button
    "previewInput", // the student count number input
    "minMax", // group_min and group_max inputs
    "groupingEnabled",
    "destructiveWarning",
    "minInput",
    "maxInput",
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
    const enabled = event.target.checked;
    this.applyEnabledState(enabled);

    if (enabled) {
      if (!this.minInputTarget.value) this.minInputTarget.value = "2";
      if (!this.maxInputTarget.value) this.maxInputTarget.value = "4";
    }
  }

  confirmSave(event) {
    const wasEnabledOriginally = this.enabledValue;
    const isEnabledNow = this.groupingEnabledTarget.checked;

    // 1. Check for Destructive OFF State
    if (wasEnabledOriginally && !isEnabledNow) {
      const message =
        "Are you sure you want to disable the grouping system? All draft groups will be deleted.";
      if (!confirm(message)) {
        event.preventDefault();
        return; // Halt execution
      }
    }

    // 2. Validate ON State (Prevent backend errors)
    if (isEnabledNow) {
      if (!this.minInputTarget.value || !this.maxInputTarget.value) {
        alert("Please set both a minimum and maximum group size.");
        // Highlight inputs in red
        if (!this.minInputTarget.value)
          this.minInputTarget.classList.add("border-red-500");
        if (!this.maxInputTarget.value)
          this.maxInputTarget.classList.add("border-red-500");

        event.preventDefault(); // Halt form submission
      }
    }
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

  applyEnabledState(isEnabledNow) {
    if (!this.hasGroupingOptionsTarget) return;

    // Show/hide the settings panel
    this.groupingOptionsTarget.classList.toggle("hidden", !isEnabledNow);

    // Show/hide the destructive warning (Only show if it was originally ON, and is now OFF)
    if (this.hasDestructiveWarningTarget) {
      const showWarning = this.enabledValue && !isEnabledNow;
      this.destructiveWarningTarget.classList.toggle("hidden", !showWarning);
    }
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
