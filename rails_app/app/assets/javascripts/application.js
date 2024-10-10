//= require jquery
//= require jquery3
//= require rails-ujs
//= require turbolinks
//= require popper
//= require bootstrap
//= require blacklight/blacklight
//= require_tree .

Blacklight.onLoad(function() {
    // Enable tooltips
    // This can be updated to use vanilla javascript
    // once we move to Bootstrap 5.
    $(function () {
        $('[data-toggle="tooltip"]').tooltip()
    });

    // Enable request submit button when at least one checkbox is selected.
    // Disable if none are selected.
    let requestCheckboxes = document.querySelectorAll('input.request-checkbox-input');
    if (requestCheckboxes) {
        requestCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('click', () => {
                let selectedCheckboxes = document.querySelectorAll('input.request-checkbox-input[type="checkbox"]:checked').length;
                document.querySelector('#submit-request').disabled = selectedCheckboxes === 0;
            });
        });
    }

    // facilitate styling by applying class if descendents contain
    // a collapsable element
    let collapsableElements = document.querySelectorAll('.h5-collapse');
    if (collapsableElements) {
        collapsableElements.forEach(element => {
            element.addEventListener('click', (event) => {
                event.target.closest('.collection-inventory-card .level-2')
                    .classList.toggle('has-collapsed');
            });
        });
    }
});
