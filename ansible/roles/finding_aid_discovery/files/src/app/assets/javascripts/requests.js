Blacklight.onLoad(function() {
    'use strict';

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
