Blacklight.onLoad(function() {
    'use strict';

    // Toggle toggler for other items in the same container
    $('.request-checkbox-input').click(function() {
        let name = $(this).attr('name');
        $('.request-checkbox-input[name="' + name + '"]')
            .prop('checked', this.checked);
    })

    // Handle Submit of Request Confirmation form
    $('#aeonRequestForm').on('submit', function() {
        const $form = $(this);
        $.post({
            url: '/requests/prepare',
            data: $form.serialize(),
            async: false
        }).done(function(data) {
            $form.attr('action', data.url);
            $form.find(':input').prop('disabled', true);
            $form.append($.map(data.body, function (k, v) {
                // 'Request' param must be duplicated to cause multiple requests
                if(v.startsWith('Request_')) { v = 'Request' }
                return $('<input>', {type: 'hidden', name: v, value: k});
            }));
        }).fail(function() {
            alert('Something unexpected happened. Please try again.');
        });
        return true;
    });
});
