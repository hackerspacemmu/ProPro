import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "row"];

  connect() {
    this._onBaseInput = () => this.#updateAllRows();
    this.#baseInput()?.addEventListener("input", this._onBaseInput);
    this.#syncBaseInputState();
  }

  disconnect() {
    this.#baseInput()?.removeEventListener("input", this._onBaseInput);
  }

  toggle(event) {
    this.panelTarget.classList.toggle("hidden", !event.target.checked);
  }

  toggleAutoCalculate(event) {
    this.#setBaseInputDisabled(event.target.checked);
  }

  updateRow(event) {
    const row = event.target.closest("[data-supervisor-capacity-target='row']");
    this.#renderRow(row);
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  #syncBaseInputState() {
    const autoCalcCheckbox = document.getElementById(
      "course_supervisor_auto_calculate_enabled",
    );
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
    const offset = parseInt(row.querySelector("[data-offset]")?.value) || 0;
    const eff = Math.max(0, base + offset);
    const sign = offset >= 0 ? `+ ${offset}` : `- ${Math.abs(offset)}`;
    row.querySelector("[data-result]").textContent = eff;
    row.querySelector("[data-formula]").textContent = `(${base} ${sign})`;
  }

  #baseValue() {
    return parseInt(this.#baseInput()?.value) || 0;
  }

  #baseInput() {
    return document.getElementById("supervisor_projects_limit_visible");
  }
}
