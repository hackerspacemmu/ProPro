import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["row"];

  connect() {
    this._onBaseInput = () => this.#updateAllRows();
    this.#baseInput()?.addEventListener("input", this._onBaseInput);
    this.#syncBaseInputState();
    this.#updateAllRows();
  }

  disconnect() {
    this.#baseInput()?.removeEventListener("input", this._onBaseInput);
  }

  toggleAutoCalculate(event) {
    this.#setBaseInputDisabled(event.target.checked);
    this.#updateAllRows();
  }

  updateRow(event) {
    const row = event.target.closest("[data-supervisor-capacity-target='row']");
    if (!row) return;

    const excludedCheckbox = row.querySelector("[data-excluded]");
    const offsetInput = row.querySelector("[data-offset]");
    const excluded = excludedCheckbox?.checked;

    if (offsetInput) {
      offsetInput.disabled = excluded;
      offsetInput.classList.toggle("opacity-50", excluded);
      offsetInput.classList.toggle("cursor-not-allowed", excluded);
      offsetInput.classList.toggle("bg-gray-100", excluded);
    }

    row.classList.toggle("opacity-60", excluded);
    this.#renderRow(row);
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  #syncBaseInputState() {
    const autoCalcCheckbox = document.getElementById("course_supervisor_auto_calculate_enabled");
    if (autoCalcCheckbox) this.#setBaseInputDisabled(autoCalcCheckbox.checked);
  }

  #setBaseInputDisabled(disabled) {
    const input = this.#baseInput();
    if (!input) return;
    input.disabled = disabled;
    input.classList.toggle("opacity-50", disabled);
    input.classList.toggle("cursor-not-allowed", disabled);
    input.classList.toggle("bg-gray-100", disabled);
  }

  #updateAllRows() {
    this.rowTargets.forEach((row) => this.#renderRow(row));
  }

  #renderRow(row) {
    if (!row) return;

    const base = this.#baseValue();
    const excludedCheckbox = row.querySelector("[data-excluded]");
    const offsetInput = row.querySelector("[data-offset]");
    const excluded = excludedCheckbox?.checked;
    const offset = parseInt(offsetInput?.value, 10) || 0;
    const eff = excluded ? 0 : base + offset;
    const sign = offset >= 0 ? `+ ${offset}` : `- ${Math.abs(offset)}`;

    row.querySelector("[data-result]").textContent = eff;
    row.querySelector("[data-formula]").textContent = excluded ? "(excluded)" : `(${base} ${sign})`;
  }

  #baseValue() {
    const autoCalcCheckbox = document.getElementById("course_supervisor_auto_calculate_enabled");
    if (autoCalcCheckbox?.checked) {
      return parseInt(this.element.dataset.supervisorCapacityBaseValue, 10) || 0;
    }

    return parseInt(this.#baseInput()?.value, 10) || 0;
  }

  #baseInput() {
    return document.getElementById("supervisor_projects_limit_visible");
  }
}
