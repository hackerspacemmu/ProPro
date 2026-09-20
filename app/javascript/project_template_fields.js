document.addEventListener("turbo:load", function () {
  const addFieldBtn = document.getElementById("add-field-btn");
  const templateFields = document.getElementById("template-fields");

  if (!addFieldBtn) return;

  let fieldIndex =
    Number(addFieldBtn.dataset.fieldIndex) ||
    templateFields.querySelectorAll(".field-row").length;

  // Field type options from Rails enum
  const fieldTypeOptions = [
    { value: "shorttext", label: "Short Text" },
    { value: "textarea", label: "Paragraph" },
    { value: "dropdown", label: "Dropdown" },
    { value: "radio", label: "Radio" },
  ];

  const applicableToOptions = [
    { value: "topics", label: "Topics" },
    { value: "proposals", label: "Proposals" },
    { value: "both", label: "Both" },
  ];

  // Generate field type select options HTML
  function generateFieldTypeOptions() {
    return fieldTypeOptions
      .map(
        (option) => `<option value="${option.value}">${option.label}</option>`,
      )
      .join("");
  }

  // Generate applicable to select options HTML
  function generateApplicableToOptions() {
    return applicableToOptions
      .map(
        (option) => `<option value="${option.value}">${option.label}</option>`,
      )
      .join("");
  }

  // Create new field HTML directly (Tailwind tr format)
  function createNewFieldHTML(index) {
    return `
      <tr
        class="field-row group bg-white transition-colors hover:bg-surface-hover/60 select-none"
        data-field-index="${index}"
        data-controller="project-template-fields"
        data-is-project-title="false"
      >
        <input type="hidden"
              name="project_template[project_template_fields_attributes][${index}][position]"
              value="${index+1}"
              class="position-input">

        <td class="table-cell pl-16 pr-6 py-5 align-top">
          <div class="relative">
            <div class="flex items-center justify-end absolute -left-12 top-1/2 -translate-y-1/2 w-11 h-8">
              <div class="drag-handle flex items-center justify-center p-1 flex-shrink-0 opacity-0 group-hover:opacity-100 pointer-coarse:opacity-100 transition-opacity cursor-grab active:cursor-grabbing pointer-coarse:touch-pan-y text-on-surface-muted hover:text-primary" title="Drag to reorder" oncontextmenu="return false;">
                <span class="material-symbols-outlined text-[18px]">drag_indicator</span>
              </div>

              <button
                type="button"
                class="remove-field flex items-center justify-center w-8 h-8 text-on-surface-muted opacity-60 hover:opacity-100 hover:bg-error-container hover:text-error rounded-md transition-all flex-shrink-0"
                title="Remove Field"
                data-action="click->project-template-fields#remove"
              >
                <svg class="h-5 w-5 pointer-events-none" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>

            <textarea
              name="project_template[project_template_fields_attributes][${index}][label]"
              placeholder="e.g. Project Title"
              rows="1"
              class="block w-full px-3 py-2.5 border border-outline rounded-lg focus:ring-1 focus:ring-primary focus:border-primary text-[13.5px] resize-none overflow-y-auto max-[640px]:text-[16px] [field-sizing:content]"
              data-controller="textarea-resize"
              data-action="input->textarea-resize#resize"
            ></textarea>
          </div>
        </td>

        <td class="table-cell px-6 py-5 align-top">
          <textarea
            name="project_template[project_template_fields_attributes][${index}][hint]"
            placeholder="Instructions…"
            rows="1"
            class="block w-full px-3 py-2.5 border border-outline rounded-lg focus:ring-1 focus:ring-primary focus:border-primary text-[13.5px] text-on-surface-variant resize-none overflow-y-auto max-[640px]:text-[16px] [field-sizing:content]"
            data-controller="textarea-resize"
            data-action="input->textarea-resize#resize"
          ></textarea>
        </td>

        <td class="table-cell px-6 py-5 align-top">
          <div class="relative">
            <select
              name="project_template[project_template_fields_attributes][${index}][field_type]"
              class="field-type-select block w-full py-2.5 pl-3 pr-7 border border-outline rounded-lg text-[13.5px] cursor-pointer appearance-none focus:ring-1 focus:ring-primary focus:border-primary max-[640px]:text-[16px]"
            >
              <option value="">Select field type</option>
              ${generateFieldTypeOptions()}
            </select>
            <span class="chevron material-symbols-outlined text-[18px] text-on-surface-variant pointer-events-none absolute right-2 top-1/2 -translate-y-1/2">expand_more</span>
          </div>
        </td>

        <td class="table-cell px-6 py-5 align-top">
          <div class="relative">
            <select
              name="project_template[project_template_fields_attributes][${index}][applicable_to]"
              class="block w-full py-2.5 pl-3 pr-7 border border-outline rounded-lg text-[13.5px] cursor-pointer appearance-none focus:ring-1 focus:ring-primary focus:border-primary max-[640px]:text-[16px]"
            >
              ${generateApplicableToOptions()}
            </select>
            <span class="chevron material-symbols-outlined text-[18px] text-on-surface-variant pointer-events-none absolute right-2 top-1/2 -translate-y-1/2">expand_more</span>
          </div>
        </td>

        <td class="table-cell px-6 py-5 align-top" data-project-template-fields-target="optionsContainer">
          <div class="options-section hidden w-full">
            <button type="button"
                    class="add-option-btn text-[12.5px] text-on-surface-variant bg-transparent border border-dashed border-outline rounded-md py-1.5 px-2.5 w-fit hover:text-primary hover:border-primary transition-colors cursor-pointer mt-0.5"
                    data-field-index="${index}"
                    data-field-type="dropdown"
                    data-option-index="0">
              + Add Option
            </button>
          </div>
          <input type="hidden" name="project_template[project_template_fields_attributes][${index}][_destroy]" value="0" class="destroy-flag">
        </td>

        <td class="table-cell px-6 py-5 whitespace-nowrap align-top">
          <div class="flex items-center h-10">
            <input type="hidden" name="project_template[project_template_fields_attributes][${index}][required]" value="0">
            <input type="checkbox"
                  name="project_template[project_template_fields_attributes][${index}][required]"
                  value="1"
                  class="h-5 w-5 rounded border-outline accent-primary cursor-pointer">
          </div>
        </td>

        <td class="table-cell px-6 py-5 whitespace-nowrap align-top">
          <div class="flex items-center h-10" title="Allow editing after approval">
            <input type="hidden" name="project_template[project_template_fields_attributes][${index}][free_edit]" value="0">
            <input type="checkbox"
                  name="project_template[project_template_fields_attributes][${index}][free_edit]"
                  value="1"
                  class="h-5 w-5 rounded border-outline accent-success cursor-pointer">
          </div>
        </td>
      </tr>
    `;
  }

  // Create dropdown option HTML (Tailwind format)
  function createDropdownOptionHTML(fieldIndex, optionIndex, optionValue = "") {
    return `
      <div class="dropdown-option-row group/opt flex items-center gap-2 py-1 px-2 rounded hover:bg-surface-variant transition-colors"
            data-field-index="${fieldIndex}"
            data-option-index="${optionIndex}">
        <input type="text"
               name="project_template[project_template_fields_attributes][${fieldIndex}][options][]"
               value="${optionValue}"
               placeholder="Option ${optionIndex + 1}"
               autocomplete="dropdown-option"
               class="flex-1 min-w-0 text-[12.5px] py-1 px-2 border border-transparent rounded-md bg-surface-tint focus:border-primary focus:bg-white focus:ring-1 focus:ring-primary focus:outline-none max-[640px]:text-[16px]">
        <button type="button" class="remove-option w-5 h-5 flex items-center justify-center rounded-md text-on-surface-muted opacity-0 group-hover/opt:opacity-100 hover:bg-error-container hover:text-error transition-all text-sm cursor-pointer">×</button>
      </div>
    `;
  }

  // Create radio option HTML (Tailwind format)
  function createRadioOptionHTML(fieldIndex, optionIndex, optionValue = "") {
    return `
      <div class="radio-option-cell group/opt flex items-center gap-2 py-1 px-2 rounded hover:bg-surface-variant transition-colors"
            data-field-index="${fieldIndex}"
            data-option-index="${optionIndex}">
        <input type="radio"
               name="preview_field_${fieldIndex}"
               disabled
               class="accent-primary shrink-0">
        <input type="text"
               name="project_template[project_template_fields_attributes][${fieldIndex}][options][]"
               value="${optionValue}"
               placeholder="Option ${optionIndex + 1}"
               autocomplete="radio-option"
               class="flex-1 min-w-0 text-[12.5px] py-1 px-2 border border-transparent rounded-md bg-surface-tint focus:border-primary focus:bg-white focus:ring-1 focus:ring-primary focus:outline-none max-[640px]:text-[16px]">
        <button type="button" class="remove-option w-5 h-5 flex items-center justify-center rounded-md text-on-surface-muted opacity-0 group-hover/opt:opacity-100 hover:bg-error-container hover:text-error transition-all text-sm cursor-pointer">×</button>
      </div>
    `;
  }

  // Add new field
  addFieldBtn.addEventListener("click", function (e) {
    e.preventDefault();

    const newFieldHTML = createNewFieldHTML(fieldIndex);
    templateFields.insertAdjacentHTML("beforeend", newFieldHTML);

    // Hide options section by default for new fields
    const rows = templateFields.querySelectorAll(".field-row");
    const newFieldRow = rows[rows.length - 1];
    const optionsSection = newFieldRow.querySelector(".options-section");

    if (optionsSection) {
      optionsSection.classList.add("hidden");
    }

    fieldIndex++;
  });

  // Handle field type changes
  templateFields.addEventListener("change", function (e) {
    if (!e.target.classList.contains("field-type-select")) return;

    const fieldRow = e.target.closest(".field-row");
    const isProjectTitle = fieldRow.dataset.isProjectTitle === "true";

    if (isProjectTitle) return;

    const optionsSection = fieldRow.querySelector(".options-section");
    const addOptionBtn = optionsSection.querySelector(".add-option-btn");
    const fieldType = e.target.value;

    if (optionsSection) {
      if (fieldType === "dropdown" || fieldType === "radio") {
        optionsSection.classList.remove("hidden");

        const existingContainer = optionsSection.querySelector(
          ".options-list, .radio-grid",
        );
        if (existingContainer) {
          existingContainer.remove();
        }

        // Create new container based on field type
        const containerHTML =
          fieldType === "dropdown"
            ? '<div class="options-list flex flex-col gap-1 mb-2"></div>'
            : '<div class="radio-grid flex flex-col gap-1 mb-2"></div>';

        addOptionBtn.insertAdjacentHTML("beforebegin", containerHTML);

        // Update button data attributes
        if (addOptionBtn) {
          addOptionBtn.dataset.fieldType = fieldType;
          addOptionBtn.dataset.optionIndex = "0";
          addOptionBtn.click();
        }
      } else {
        optionsSection.classList.add("hidden");
        // Clear options when switching away from dropdown/radio
        const container = optionsSection.querySelector(
          ".options-list, .radio-grid",
        );
        if (container) {
          container.remove();
        }
      }
    }
  });

  // Handle clicks (remove field, add option, remove option)
  templateFields.addEventListener("click", function (e) {
    if (e.target.closest(".remove-field")) {
      e.preventDefault();

      const btn = e.target.closest(".remove-field");
      const fieldRow = btn.closest(".field-row");
      const isProjectTitle = fieldRow.dataset.isProjectTitle === "true";

      if (isProjectTitle) {
        console.log("Cannot delete Project Title field");
        return;
      }

      const destroyFlag = fieldRow.querySelector(".destroy-flag");

      if (destroyFlag) {
        destroyFlag.value = "1";
        fieldRow.style.display = "none";
      } else {
        fieldRow.remove();
      }
    }

    // Add option
    const addBtn = e.target.closest(".add-option-btn");
    if (addBtn) {
      e.preventDefault();

      const btn = addBtn;
      const fieldIndex = btn.dataset.fieldIndex;
      const optionIndex = parseInt(btn.dataset.optionIndex, 10);
      const fieldType = btn.dataset.fieldType;

      const optionsSection = btn.closest(".options-section");
      const containerSelector =
        fieldType === "dropdown" ? ".options-list" : ".radio-grid";
      let container = optionsSection.querySelector(containerSelector);

      // Create container if it doesn't exist
      if (!container) {
        const containerHTML =
          fieldType === "dropdown"
            ? '<div class="options-list flex flex-col gap-1 mb-2"></div>'
            : '<div class="radio-grid flex flex-col gap-1 mb-2"></div>';
        btn.insertAdjacentHTML("beforebegin", containerHTML);
        container = optionsSection.querySelector(containerSelector);
      }

      // Create and add option HTML
      const optionHTML =
        fieldType === "dropdown"
          ? createDropdownOptionHTML(fieldIndex, optionIndex)
          : createRadioOptionHTML(fieldIndex, optionIndex);

      container.insertAdjacentHTML("beforeend", optionHTML);

      // Update option index for next addition
      btn.dataset.optionIndex = optionIndex + 1;
    }

    // Remove option
    const removeOptionBtn = e.target.closest(".remove-option");

    if (removeOptionBtn) {
      e.preventDefault();

      // Find the wrapper (whether it's dropdown or radio)
      const optionRow = removeOptionBtn.closest(
        ".dropdown-option-row, .radio-option-cell",
      );

      if (optionRow) {
        optionRow.remove();
      }
    }
  });

  // Initial check to disable remove button on Project Title
  templateFields.querySelectorAll(".field-row").forEach((row) => {
    if (row.dataset.isProjectTitle === "true") {
      const btn = row.querySelector(".remove-field");
      if (btn) {
        btn.disabled = true;
        btn.title = "Cannot remove title";
      }
      const requiredCheckbox = row.querySelector(
        'input[type="checkbox"][name*="[required]"]',
      );
      if (requiredCheckbox) {
        requiredCheckbox.checked = true;
        requiredCheckbox.disabled = true;
        requiredCheckbox.required = true;
        requiredCheckbox.title = "Title is Required";
        requiredCheckbox.classList.add("cursor-not-allowed");
      }
    }
  });

  // Focus handling for visual feedback
  templateFields.addEventListener("focusin", function (e) {
    const row = e.target.closest(".field-row");
    if (row) row.classList.add("bg-surface-hover");
  });

  templateFields.addEventListener("focusout", function (e) {
    const row = e.target.closest(".field-row");
    if (row && !row.contains(document.activeElement)) {
      row.classList.remove("bg-surface-hover");
    }
  });
});