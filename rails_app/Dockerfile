# Global Build Args ----------------------------------
# Bundle home
ARG BUNDLE_HOME=vendor/bundle

# Image tag
ARG IMAGE_TAG=3.1.6-alpine3.19

# The root of our app
ARG PROJECT_ROOT=/home/app

# Rails env
ARG RAILS_ENV=development


# Build Stage ----------------------------------------
FROM ruby:${IMAGE_TAG} AS base

ARG RUBY_MAJOR
ENV RUBY_MAJOR=3.1.0

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"

WORKDIR ${PROJECT_ROOT}

# Install build packages
RUN apk add --no-cache --virtual build-dependencies \
      build-base \
      git  \
      postgresql-dev

COPY Gemfile* ./

RUN bundle config path ${PROJECT_ROOT}/${BUNDLE_HOME} && \
    set -eux; \
    if [ "${RAILS_ENV}" = "development" ]; then \
    bundle config set with "development:test:assets"; \
    else \
    bundle config set without "development:test:assets"; \
    fi

RUN --mount=type=secret,id=sidekiq_pro_credentials \
    bundle config set --local gems.contribsys.com $(cat /run/secrets/sidekiq_pro_credentials)

RUN MAKE="make -j $(nproc)" bundle install && \
  rm -rf ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/cache/*.gem && \
  find ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/gems/ \( -name "*.c" -o -name "*.o" \) -delete

COPY . .


# Development Stage ----------------------------------
FROM ruby:${IMAGE_TAG} as development

ARG RUBY_MAJOR
ENV RUBY_MAJOR=3.1.0

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

# Set Rails env
ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/"
ENV GEM_PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/"
ENV NLS_LANG=$LANG
ENV PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin:${PATH}"

WORKDIR ${PROJECT_ROOT}

RUN apk add --no-cache \
      build-base \
      curl \
      git \
      libc6-compat \
      nodejs \
      postgresql-dev \
      shadow \
      su-exec \
      tzdata \
      yarn && \
    addgroup -S app && adduser -S app -G app -h ${PROJECT_ROOT} -s /bin/ash && \
    mkdir -p ${PROJECT_ROOT}/tmp/pids

COPY --from=base ${PROJECT_ROOT}/docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

RUN mkdir -p ${PROJECT_ROOT}/app/assets/builds/ && \
    SECRET_KEY_BASE=x FINDING_AID_DISCOVERY_URL=x bundle exec rake assets:precompile && \
    find . -type d -exec chmod 755 {} + && \
    find . -type f -exec chmod 644 {} + && \
    find bin -type f -exec chmod 744 {} + && \
    chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin/ && \
    chown -R app:app .

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000
VOLUME ${PROJECT_ROOT}

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000"]


# Production Stage -----------------------------------
FROM ruby:${IMAGE_TAG} as production

ARG RUBY_MAJOR
ENV RUBY_MAJOR=3.1.0

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}

# Set Rails env
ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/"
ENV GEM_PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/"
ENV NLS_LANG=$LANG
ENV PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin:${PATH}"
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

WORKDIR ${PROJECT_ROOT}

COPY ./docker-entrypoint.sh /usr/local/bin/
COPY --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

RUN apk add --no-cache \
      curl \
      libc6-compat \
      nodejs \
      postgresql-dev \
      shadow \
      su-exec \
      tzdata \
      yarn && \
    addgroup -S app && adduser -S app -G app -h ${PROJECT_ROOT} -s /bin/ash && \
    mkdir -p ${PROJECT_ROOT}/tmp/pids

COPY --from=base ${PROJECT_ROOT}/docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

RUN mkdir -p ${PROJECT_ROOT}/app/assets/builds/ && \
    SECRET_KEY_BASE=x FINDING_AID_DISCOVERY_URL=x bundle exec rake assets:precompile && \
    find . -type d -exec chmod 755 {} + && \
    find . -type f -exec chmod 644 {} + && \
    find bin -type f -exec chmod 744 {} + && \
    chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}/bin/ && \
    chown -R app:app .

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000
VOLUME ${PROJECT_ROOT}

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000"]
