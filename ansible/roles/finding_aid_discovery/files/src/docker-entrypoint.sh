#!/bin/sh
set -e

if [ "$1" = "bundle" -a "$2" = "exec" -a "$3" = "puma" ] || [ "$1" = "bundle" -a "$2" = "exec" -a "$3" = "sidekiq" ]; then
    if [ ! -z "${APP_UID}" ] && [ ! -z "${APP_GID}" ]; then
        usermod -u ${APP_UID} app
        groupmod -g ${APP_GID} app
    fi

    if [ "${RAILS_ENV}" = "development" ]; then
        bundle config --local path ${PROJECT_ROOT}/vendor/bundle
        bundle config set --local with 'development:test:assets'
        bundle install -j$(nproc) --retry 3
        
        # since we are running a dev env we remove node_modules and install our dependencies
        su - app -c $(rm -rf node_modules && yarn install --no-bin-links)

        chown -R app:app .
    fi

    # remove puma server.pid
    if [ -f ${PROJECT_ROOT}/tmp/pids/server.pid ]; then
        rm -f ${PROJECT_ROOT}/tmp/pids/server.pid
    fi

    # run db migrations on finding_aid_discovery container
    if [ "$1" = "bundle" -a "$2" = "exec" -a "$3" = "puma" ]; then
        bundle exec rake db:migrate
        bundle exec rake tools:ensure_sitemap
        bundle exec rake tools:robotstxt
    fi

    # run the application as the app user
    exec su-exec app "$@"
fi

exec "$@"
