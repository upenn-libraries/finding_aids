# Global Build Args ----------------------------------
# Bundle home
ARG BUNDLE_HOME=vendor/bundle

# Image tag
ARG IMAGE_TAG=3.1.2-alpine3.16

# The root of our app
ARG PROJECT_ROOT=/home/app

# Rails env
ARG RAILS_ENV=development


# Build Stage ----------------------------------------
FROM ruby:${IMAGE_TAG} AS base

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"

WORKDIR ${PROJECT_ROOT}

COPY Gemfile* ./

# Install build packages
RUN apk add --no-cache --virtual build-dependencies \
        build-base \
        git  \
        postgresql-dev && \
    bundle config path ${PROJECT_ROOT}/${BUNDLE_HOME} && \
    set -eux; \
    if [ "${RAILS_ENV}" = "development" ]; then \
    bundle config set with "development:test:assets"; \
    else \
    bundle config set without "development:test:assets"; \
    fi && \
    bundle install -j$(nproc) --retry 3 && \
    rm -rf ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/cache/*.gem && \
    find ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/gems/ \( -name "*.c" -o -name "*.o" \) -delete && \
    apk del build-dependencies

COPY . .


# Development Stage ----------------------------------
FROM ruby:${IMAGE_TAG} as development

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV}

# Set Rails env
ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/"
ENV GEM_PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/"
ENV NLS_LANG=$LANG
ENV PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/bin:${PATH}"

WORKDIR ${PROJECT_ROOT}

COPY ./docker-entrypoint.sh /usr/local/bin/
COPY --from=base ${PROJECT_ROOT} ${PROJECT_ROOT}

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
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    addgroup -S app && adduser -S app -G app -h ${PROJECT_ROOT} -s /bin/ash && \
    mkdir -p ${PROJECT_ROOT}/tmp/pids && \
    find . -type d -exec chmod 755 {} + && \
    find . -type f -exec chmod 644 {} + && \
    find bin -type f -exec chmod 744 {} + && \
    chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/bin/ && \
    chown -R app:app .

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000
VOLUME ${PROJECT_ROOT}

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000"]


# Production Stage -----------------------------------
FROM ruby:${IMAGE_TAG} as production

ARG BUNDLE_HOME
ENV BUNDLE_HOME=${BUNDLE_HOME}

ARG PROJECT_ROOT
ENV PROJECT_ROOT=${PROJECT_ROOT}

ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}

# Set Rails env
ENV BUNDLE_APP_CONFIG="${PROJECT_ROOT}/.bundle"
ENV GEM_HOME="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/"
ENV GEM_PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/"
ENV NLS_LANG=$LANG
ENV PATH="${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/bin:${PATH}"
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
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    addgroup -S app && adduser -S app -G app -h ${PROJECT_ROOT} -s /bin/ash && \
    SECRET_KEY_BASE=x FINDING_AID_DISCOVERY_URL=x rails assets:precompile && \
    mkdir -p ${PROJECT_ROOT}/tmp/pids && \
    find . -type d -exec chmod 755 {} + && \
    find . -type f -exec chmod 644 {} + && \
    find bin -type f -exec chmod 744 {} + && \
    chmod +x -R ${PROJECT_ROOT}/${BUNDLE_HOME}/ruby/${RUBY_MAJOR}.0/bin/ && \
    chown -R app:app .

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000
VOLUME ${PROJECT_ROOT}

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000"]
