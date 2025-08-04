document.addEventListener("turbo:load", function() {
  const addFieldBtn    = document.getElementById('add-field-btn');
  const templateFields = document.getElementById('template-fields');
  const courseId       = addFieldBtn.dataset.courseId;

  if (!addFieldBtn) return;

  let fieldIndex = Date.now();

  addFieldBtn.addEventListener('click', function(e) {
    e.preventDefault();

    const url = '/courses/' + courseId + '/project_template/new_field' +
                '?index=' + fieldIndex;

    fetch(url)
      .then(response => response.text())
      .then(html => {
        console.log('Adding field HTML:', html);
        templateFields.insertAdjacentHTML('beforeend', html);
        const rows          = templateFields.querySelectorAll('.field-row');
        const newFieldRow   = rows[rows.length - 1];
        const optionsSection = newFieldRow.querySelector('.options-section');

        if (optionsSection) {
          optionsSection.classList.add('hidden');
        }

        fieldIndex++;
      })
      .catch(error => {
        console.error('Error adding field:', error);
      });
  });

  templateFields.addEventListener('change', function(e) {
    if (!e.target.classList.contains('field-type-select')) return;

    const fieldRow      = e.target.closest('.field-row');
    const labelInput    = fieldRow.querySelector('input[name*="[label]"]');
    const isProjectTitle = labelInput && labelInput.value === "Project Title";
    
    if (isProjectTitle) return;

    const optionsSection = fieldRow.querySelector('.options-section');
    const addOptionBtn   = optionsSection.querySelector('.add-option-btn');
    const fieldType      = e.target.value;

    if (optionsSection) {
      optionsSection.style.display = '';
      if (fieldType === 'dropdown' || fieldType === 'radio') {
        optionsSection.classList.remove('hidden');
        if (addOptionBtn) {
          addOptionBtn.dataset.fieldType = fieldType;
        }
      } else {
        optionsSection.classList.add('hidden');
      }
    }
  });

  templateFields.addEventListener('click', function(e) {
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
  });

  templateFields.addEventListener('click', function(e) {
    if (e.target.classList.contains('add-option-btn')) {
      e.preventDefault();

      const btn         = e.target;
      const fieldIndex  = btn.dataset.fieldIndex;
      const optionIndex = parseInt(btn.dataset.optionIndex, 10);
      const fieldType   = btn.dataset.fieldType;
      
      console.log('Add option clicked:', { fieldIndex, optionIndex, fieldType });
      
      const optionsSection = btn.closest('.options-section');
      console.log('Options section found:', optionsSection);
      
      const containerSelector = fieldType === 'dropdown' ? '.options-list' : '.radio-grid';
      let container = optionsSection.querySelector(containerSelector);
      
      console.log('Container selector:', containerSelector);
      console.log('Container found:', container);
      
      if (!container) {
        const containerHTML = fieldType === 'dropdown' 
          ? '<div class="options-list"></div>'
          : '<div class="radio-grid"></div>';
        optionsSection.insertAdjacentHTML('afterbegin', containerHTML);
        container = optionsSection.querySelector(containerSelector);
        console.log('Created new container:', container);
      }

      if (!container) {
        console.error('Could not find or create container for options');
        return;
      }

      const fetcher = fieldType === 'dropdown' ? createDropdownOption : createRadioOption;

      fetcher(fieldIndex, optionIndex).then(html => {
        console.log('Received option HTML:', html);
        container.insertAdjacentHTML('beforeend', html);
        btn.dataset.optionIndex = optionIndex + 1;
      }).catch(error => {
        console.error('Error creating option:', error);
      });
    }

    if (e.target.classList.contains('remove-option')) {
      e.preventDefault();
      const optionRow = e.target.closest('.dropdown-option-row, .radio-option-cell');
      optionRow && optionRow.remove();
    }
  });

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

  function createDropdownOption(fieldIndex, optionIndex) {
    const url = '/courses/' + courseId +
                '/project_template/new_option' +
                '?field_index='  + fieldIndex +
                '&option_index=' + optionIndex +
                '&field_type=dropdown';

    return fetch(url).then(response => response.text());
  }

  function createRadioOption(fieldIndex, optionIndex) {
    const url = '/courses/' + courseId +
                '/project_template/new_option' +
                '?field_index='  + fieldIndex +
                '&option_index=' + optionIndex +
                '&field_type=radio';

    return fetch(url).then(response => response.text());
  }
});