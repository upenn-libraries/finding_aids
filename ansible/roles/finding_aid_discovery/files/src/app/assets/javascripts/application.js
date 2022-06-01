//= require jquery
//= require jquery3
//= require rails-ujs
//= require turbolinks
//= require popper
//= require bootstrap
//= require blacklight/blacklight
//= require 'blacklight_range_limit'
//= require_tree .

Blacklight.onLoad(function() {
    //# Enable tooltips
    $(function () {
        $('[data-toggle="tooltip"]').tooltip()
    });

    // facilitate styling by applying class if descendents contain
    // a collapsable element
    $('.h5-collapse').click(function() {
        $(this).parents('.collection-inventory-card .level-2')
            .toggleClass('has-collapsed');
    });
});
