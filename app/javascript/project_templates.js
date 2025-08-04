document.addEventListener("turbo:load", function() {
  const addFieldBtn    = document.getElementById('add-field-btn');
  const templateFields = document.getElementById('template-fields');
  
  if (!addFieldBtn) return;

  let fieldIndex = Date.now();

  // Field type options from Rails enum
  const fieldTypeOptions = [
    { value: 'shorttext', label: 'Shorttext' },
    { value: 'textarea', label: 'Textarea' },
    { value: 'dropdown', label: 'Dropdown' },
    { value: 'radio', label: 'Radio' }
  ];

  // Applicable to options from Rails enum  
  const applicableToOptions = [
    { value: 'topics', label: 'Topics' },
    { value: 'proposals', label: 'Proposals' },
    { value: 'both', label: 'Both' }
  ];

  // Generate field type select options HTML
  function generateFieldTypeOptions() {
    return fieldTypeOptions.map(option => 
      `<option value="${option.value}">${option.label}</option>`
    ).join('');
  }

  // Generate applicable to select options HTML
  function generateApplicableToOptions() {
    return applicableToOptions.map(option => 
      `<option value="${option.value}">${option.label}</option>`
    ).join('');
  }

  // Create new field HTML directly
  function createNewFieldHTML(index) {
    return `
      <div class="field-row" data-field-index="${index}">
        <button type="button" class="remove-field">
          ×
        </button>
        
        <div class="row">
          <div class="column">
            <input type="text"
                   name="project_template[project_template_fields_attributes][${index}][label]"
                   placeholder="Field Label" />
          </div>
          <div class="hint-row">
            <textarea name="project_template[project_template_fields_attributes][${index}][hint]"
                      placeholder="Hint Text"></textarea>
          </div>  
          <div class="column">
            <select name="project_template[project_template_fields_attributes][${index}][field_type]"
                    class="field-type-select">
              <option value="">Select field type</option>
              ${generateFieldTypeOptions()}
            </select>
          </div>
          <div class="column">
            <select name="project_template[project_template_fields_attributes][${index}][applicable_to]">
              <option value="">Select applicability</option>
              ${generateApplicableToOptions()}
            </select>
          </div>
          <div class="column options-column">
            <div class="options-section hidden">
              <button type="button"
                      class="add-option-btn"
                      data-field-index="${index}"
                      data-field-type="dropdown"
                      data-option-index="0">
                + Add Option
              </button>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // Create dropdown option HTML
  function createDropdownOptionHTML(fieldIndex, optionIndex, optionValue = '') {
    return `
      <div class="dropdown-option-row"
           data-field-index="${fieldIndex}"
           data-option-index="${optionIndex}">
        <input type="text"
               name="project_template[project_template_fields_attributes][${fieldIndex}][options][]"
               value="${optionValue}"
               placeholder="Option ${optionIndex + 1}">
        <button type="button" class="remove-option">×</button>
      </div>
    `;
  }

  // Create radio option HTML  
  function createRadioOptionHTML(fieldIndex, optionIndex, optionValue = '') {
    return `
      <div class="radio-option-cell"
           data-field-index="${fieldIndex}"
           data-option-index="${optionIndex}">
        <input type="radio"
               name="preview_field_${fieldIndex}"
               disabled>
        <input type="text"
               name="project_template[project_template_fields_attributes][${fieldIndex}][options][]"
               value="${optionValue}"
               placeholder="Option ${optionIndex + 1}">
        <button type="button" class="remove-option">×</button>
      </div>
    `;
  }

  // Add new field
  addFieldBtn.addEventListener('click', function(e) {
    e.preventDefault();
    
    const newFieldHTML = createNewFieldHTML(fieldIndex);
    templateFields.insertAdjacentHTML('beforeend', newFieldHTML);
    
    // Hide options section by default for new fields
    const rows = templateFields.querySelectorAll('.field-row');
    const newFieldRow = rows[rows.length - 1];
    const optionsSection = newFieldRow.querySelector('.options-section');
    
    if (optionsSection) {
      optionsSection.classList.add('hidden');
    }
    
    fieldIndex++;
  });

  // Handle field type changes
  templateFields.addEventListener('change', function(e) {
    if (!e.target.classList.contains('field-type-select')) return;

    const fieldRow = e.target.closest('.field-row');
    const labelInput = fieldRow.querySelector('input[name*="[label]"]');
    const isProjectTitle = labelInput && labelInput.value === "Project Title";
    
    if (isProjectTitle) return;

    const optionsSection = fieldRow.querySelector('.options-section');
    const addOptionBtn = optionsSection.querySelector('.add-option-btn');
    const fieldType = e.target.value;

    if (optionsSection) {
      if (fieldType === 'dropdown' || fieldType === 'radio') {
        optionsSection.classList.remove('hidden');
        
        // Clear existing options and create appropriate container
        const existingContainer = optionsSection.querySelector('.options-list, .radio-grid');
        if (existingContainer) {
          existingContainer.remove();
        }
        
        // Create new container based on field type
        const containerHTML = fieldType === 'dropdown' 
          ? '<div class="options-list"></div>'
          : '<div class="radio-grid"></div>';
        
        addOptionBtn.insertAdjacentHTML('beforebegin', containerHTML);
        
        // Update button data attributes
        if (addOptionBtn) {
          addOptionBtn.dataset.fieldType = fieldType;
          addOptionBtn.dataset.optionIndex = '0';
        }
      } else {
        optionsSection.classList.add('hidden');
        // Clear options when switching away from dropdown/radio
        const container = optionsSection.querySelector('.options-list, .radio-grid');
        if (container) {
          container.remove();
        }
      }
    }
  });

  // Handle clicks (remove field, add option, remove option)
  templateFields.addEventListener('click', function(e) {
    // Remove field
    if (e.target.classList.contains('remove-field')) {
      e.preventDefault();
      
      const fieldRow = e.target.closest('.field-row');
      const labelInput = fieldRow.querySelector('input[name*="[label]"]');
      const isProjectTitle = labelInput && labelInput.value === "Project Title";
      
      if (isProjectTitle) {
        console.log('Cannot delete Project Title field');
        return;
      }
      
      const destroyFlag = fieldRow.querySelector('.destroy-flag');
      
      if (destroyFlag) {
        destroyFlag.value = 'true';
        fieldRow.style.display = 'none';
      } else {
        fieldRow.remove();
      }
    }

    // Add option
    if (e.target.classList.contains('add-option-btn')) {
      e.preventDefault();

      const btn = e.target;
      const fieldIndex = btn.dataset.fieldIndex;
      const optionIndex = parseInt(btn.dataset.optionIndex, 10);
      const fieldType = btn.dataset.fieldType;
      
      const optionsSection = btn.closest('.options-section');
      const containerSelector = fieldType === 'dropdown' ? '.options-list' : '.radio-grid';
      let container = optionsSection.querySelector(containerSelector);
      
      // Create container if it doesn't exist
      if (!container) {
        const containerHTML = fieldType === 'dropdown' 
          ? '<div class="options-list"></div>'
          : '<div class="radio-grid"></div>';
        btn.insertAdjacentHTML('beforebegin', containerHTML);
        container = optionsSection.querySelector(containerSelector);
      }

      // Create and add option HTML
      const optionHTML = fieldType === 'dropdown' 
        ? createDropdownOptionHTML(fieldIndex, optionIndex)
        : createRadioOptionHTML(fieldIndex, optionIndex);
      
      container.insertAdjacentHTML('beforeend', optionHTML);
      
      // Update option index for next addition
      btn.dataset.optionIndex = optionIndex + 1;
    }

    // Remove option
    if (e.target.classList.contains('remove-option')) {
      e.preventDefault();
      const optionRow = e.target.closest('.dropdown-option-row, .radio-option-cell');
      if (optionRow) {
        optionRow.remove();
      }
    }
  });

  // Focus handling for visual feedback
  templateFields.addEventListener('focusin', function(e) {
    const row = e.target.closest('.field-row');
    if (row) row.classList.add('focus-within');
  });

  templateFields.addEventListener('focusout', function(e) {
    const row = e.target.closest('.field-row');
    if (row && !row.contains(document.activeElement)) {
      row.classList.remove('focus-within');
    }
  });
});