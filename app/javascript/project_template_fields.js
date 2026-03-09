document.addEventListener("turbo:load", function () {
  const addFieldBtn = document.getElementById("add-field-btn");
  const templateFields = document.getElementById("template-fields");

  if (!addFieldBtn) return;

  let fieldIndex =
    Number(addFieldBtn.dataset.fieldIndex) ||
    templateFields.querySelectorAll(".field-row").length;

  // Field type options from Rails enum
  const fieldTypeOptions = [
    { value: "shorttext", label: "Shorttext" },
    { value: "textarea", label: "Textarea" },
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
        class="field-row group relative flex flex-col bg-white transition-colors hover:bg-gray-50/50 border-b border-gray-600 last-of-type:border-b-0 lg:table-row lg:border-none"
        data-field-index="${index}"
      >
        <td class="block lg:table-cell px-6 lg:pl-12 lg:pr-6 py-5 whitespace-nowrap align-top">
          <span class="lg:hidden text-xs font-bold text-gray-500 uppercase tracking-wide mb-1 block">Field Label</span>
          <div class="relative">
            <textarea
                   name="project_template[project_template_fields_attributes][${index}][label]"
                   placeholder="e.g. Project Title"
                   rows="1"
                   class="block w-full px-3 py-2.5 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm resize-none overflow-hidden"
                   data-controller="textarea-resize"
                   data-action="input->textarea-resize#resize"
            ></textarea>

            <button type="button" class="remove-field hidden lg:flex items-center justify-center absolute -left-10 top-1/2 -translate-y-1/2 w-8 h-8 text-gray-400 opacity-60 hover:opacity-100 hover:bg-red-50 hover:text-red-600 rounded-md transition-all" title="Remove Field">
              <svg class="h-5 w-5 pointer-events-none" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
            </button>
          </div>
        </td>

        <td class="block lg:table-cell px-6 py-5 align-top">
          <span class="lg:hidden text-xs font-bold text-gray-500 uppercase tracking-wide mb-1 block">Hint Text</span>
          <textarea name="project_template[project_template_fields_attributes][${index}][hint]"
                    placeholder="Instructions..."
                    rows="1"
                    class="block w-full px-3 py-2.5 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm resize-none overflow-hidden"
                    data-controller="textarea-resize"
                    data-action="input->textarea-resize#resize"
          ></textarea>
        </td>

        <td class="block lg:table-cell px-6 py-5 whitespace-nowrap align-top">
          <span class="lg:hidden text-xs font-bold text-gray-500 uppercase tracking-wide mb-1 block">Field Type</span>
          <select name="project_template[project_template_fields_attributes][${index}][field_type]" class="field-type-select block w-full py-2.5 pl-3 pr-8 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm cursor-pointer">
            <option value="">Select field type</option>
            ${generateFieldTypeOptions()}
          </select>
        </td>

        <td class="block lg:table-cell px-6 py-5 whitespace-nowrap align-top">
          <span class="lg:hidden text-xs font-bold text-gray-500 uppercase tracking-wide mb-1 block">Applicable To</span>
          <select name="project_template[project_template_fields_attributes][${index}][applicable_to]"
                  class="block w-full py-2.5 pl-3 pr-8 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm cursor-pointer">
            ${generateApplicableToOptions()}
          </select>
        </td>

        <td class="block lg:table-cell px-6 py-5 align-top">
          <span class="lg:hidden text-xs font-bold text-gray-500 uppercase tracking-wide mb-1 block">Options</span>

          <div class="options-section hidden w-full">
            <button type="button"
                    class="add-option-btn text-[0.8125rem] text-gray-500 bg-transparent border border-dashed border-gray-300 rounded py-2 px-3 cursor-pointer transition-all duration-150 ease-in-out w-fit hover:text-blue-600 hover:border-blue-500 hover:bg-[#f8f9fa] mt-2"
                    data-field-index="${index}"
                    data-field-type="dropdown"
                    data-option-index="0">
              + Add Option
            </button>
          </div>

          <button type="button" class="remove-field lg:hidden mt-3 inline-flex items-center text-xs text-red-500 hover:text-red-700 font-medium bg-red-50 px-3 py-2 rounded-md">
            <svg class="mr-1.5 h-4 w-4 pointer-events-none" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
            Remove Field
          </button>
        </td>

        <td class="block lg:table-cell px-6 py-5 align-top">
          <span class="lg:hidden text-xs font-bold text-gray-500 uppercase tracking-wide mb-1 block">Required</span>
          <input type="hidden"
                name="project_template[project_template_fields_attributes][${index}][required]"
                value="false">
          <input type="checkbox"
                name="project_template[project_template_fields_attributes][${index}][required]"
                value="true"
                class="block w-full py-2.5 pl-3 pr-8 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm cursor-pointer">
        </td>
      </tr>
    `;
  }

  // Create dropdown option HTML (Tailwind format)
  function createDropdownOptionHTML(fieldIndex, optionIndex, optionValue = "") {
    return `
      <div class="dropdown-option-row group flex items-center gap-2 py-1 rounded transition-colors duration-150 ease-in-out hover:bg-gray-200"
            data-field-index="${fieldIndex}"
            data-option-index="${optionIndex}">
        <input type="text"
               name="project_template[project_template_fields_attributes][${fieldIndex}][options][]"
               value="${optionValue}"
               placeholder="Option ${optionIndex + 1}"
               autocomplete="dropdown-option"
               class="flex-1 text-[0.8125rem] py-1 px-2 border border-transparent rounded-[3px] bg-[#f8f9fa] focus:border-blue-500 focus:bg-[#f8f9fa] focus:ring-1 focus:ring-blue-500 focus:outline-none">
        <button type="button" class="remove-option w-5 h-5 flex items-center justify-center border-none bg-gray-200 text-gray-500 rounded-[3px] cursor-pointer text-sm opacity-0 transition-all duration-150 ease-in-out group-hover:opacity-100 hover:bg-red-500 hover:text-white">×</button>
      </div>
    `;
  }

  // Create radio option HTML (Tailwind format)
  function createRadioOptionHTML(fieldIndex, optionIndex, optionValue = "") {
    return `
      <div class="radio-option-cell group flex items-center gap-2 py-1 rounded transition-colors duration-150 ease-in-out hover:bg-gray-200"
            data-field-index="${fieldIndex}"
            data-option-index="${optionIndex}">
        <input type="radio"
               name="preview_field_${fieldIndex}"
               disabled
               class="h-4 w-4 text-gray-400 border-gray-300 focus:ring-0">
        <input type="text"
               name="project_template[project_template_fields_attributes][${fieldIndex}][options][]"
               value="${optionValue}"
               placeholder="Option ${optionIndex + 1}"
               class="flex-1 text-[0.8125rem] py-1 px-2 border border-transparent rounded-[3px] bg-[#f8f9fa] focus:border-blue-500 focus:bg-[#f8f9fa] focus:ring-1 focus:ring-blue-500 focus:outline-none">
        <button type="button" class="remove-option w-5 h-5 flex items-center justify-center border-none bg-gray-200 text-gray-500 rounded-[3px] cursor-pointer text-sm opacity-0 transition-all duration-150 ease-in-out group-hover:opacity-100 hover:bg-red-500 hover:text-white">×</button>
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
    const labelInput = fieldRow.querySelector(
      'textarea[name*="[label]"], input[name*="[label]"]',
    );
    const isProjectTitle =
      labelInput && labelInput.value.trim() === "Project Title";

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
      const labelInput = fieldRow.querySelector(
        'textarea[name*="[label]"], input[name*="[label]"]',
      );
      const isProjectTitle =
        labelInput && labelInput.value.trim() === "Project Title";

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
    if (e.target.classList.contains("remove-option")) {
      e.preventDefault();
      const optionRow = e.target.closest(
        ".dropdown-option-row, .radio-option-cell",
      );
      if (optionRow) {
        optionRow.remove();
      }
    }
  });

  // Initial check to disable remove button on Project Title
  templateFields.querySelectorAll(".field-row").forEach((row) => {
    const labelInput = row.querySelector(
      'textarea[name*="[label]"], input[name*="[label]"]',
    );
    if (labelInput && labelInput.value.trim() === "Project Title") {
      const btn = row.querySelector(".remove-field");
      if (btn) {
        btn.disabled = true;
        btn.title = "Cannot remove title";
        btn.classList.add("opacity-50", "cursor-not-allowed");
      }
      const requiredCheckbox = row.querySelector(
        'input[type="checkbox"][name*="[required]"]'
      );
      if (requiredCheckbox) {
        requiredCheckbox.checked = true;
        requiredCheckbox.disabled = true;
        requiredCheckbox.required = true;
        requiredCheckbox.title = "Title is Required";
        
      }
    }
  });

  // Focus handling for visual feedback
  templateFields.addEventListener("focusin", function (e) {
    const row = e.target.closest(".field-row");
    if (row) row.classList.add("bg-gray-50");
  });

  templateFields.addEventListener("focusout", function (e) {
    const row = e.target.closest(".field-row");
    if (row && !row.contains(document.activeElement)) {
      row.classList.remove("bg-gray-50");
    }
  });
});
