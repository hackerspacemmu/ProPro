document.addEventListener('DOMContentLoaded', function() {
  const addFieldBtn = document.getElementById('add-field-btn');
  const templateFields = document.getElementById('template-fields');
  var courseId = addFieldBtn.dataset.courseId;
  
  if (!addFieldBtn) return;
  
  let fieldIndex = parseInt(addFieldBtn.dataset.fieldIndex) || 0;

  addFieldBtn.addEventListener('click', function() {
    var url = '/courses/' + courseId + '/project_template/new_field' + '?index=' + fieldIndex;

    fetch(url).then(function(response) { return response.text();})
    .then(function(html) {templateFields.insertedAdjacentHTML('beforehand', html); fieldIndex++;
    });
  });

  templateFields.addEventListener('change', function(e) {
    if (e.target.classList.contains('field-type-select')) {
      const fieldRow = e.target.closest('.field-row');
      const optionsSection = fieldRow.querySelector('.options-section');
      const fieldType = e.target.value;
      
      if (optionsSection) {
        optionsSection.style.display = (fieldType === 'dropdown' || fieldType === 'radio') ? 'block' : 'none'; 
      }
    }
  });
});