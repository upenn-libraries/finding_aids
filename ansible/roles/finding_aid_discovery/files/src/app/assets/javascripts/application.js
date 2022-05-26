//= require jquery
//= require jquery3
//= require rails-ujs
//= require turbolinks
//
// Required by Blacklight
//= require popper
// Twitter Typeahead for autocomplete
// require twitter/typeahead
//= require bootstrap
//= require blacklight/blacklight
//= require 'blacklight_range_limit'

Blacklight.onLoad(function() {
    //# Enable tooltips
    $(function () {
        $('[data-toggle="tooltip"]').tooltip()
    })

    // facilitate styling by applying class if descendents contain
    // a collapsable element
    $('.collection-inventory-card .level-2').each(function() {
        let $card = $(this);
        if($card.find('h5 > button').length > 0) {
            $card.addClass('has-collapsed');
        }
    });
})
