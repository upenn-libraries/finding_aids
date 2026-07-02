# Agent Instructions

## API Documentation

- **Always use context7 (ctx7)** for looking up API documentation instead of relying on pre-trained knowledge

## Git Workflow

- **Always confirm before pushing** — ask the user for permission before running `git push` or `glab mr` commands. Do not push commits or create MRs without explicit approval.

## Running Tests and Linting

Tests and linting run inside Docker containers. Use these commands from the project root:

### RuboCop

```bash
CONTAINER=$(docker exec finding-aids docker ps --filter "name=fad_finding_aid_discovery" -q | head -1)
docker exec finding-aids docker exec "$CONTAINER" sh -c "bundle exec rubocop <path>"
```

Examples:
```bash
# Rubocop on a single file
CONTAINER=$(docker exec finding-aids docker ps --filter "name=fad_finding_aid_discovery" -q | head -1)
docker exec finding-aids docker exec "$CONTAINER" sh -c "bundle exec rubocop app/controllers/catalog_controller.rb"

# Rubocop on a directory
CONTAINER=$(docker exec finding-aids docker ps --filter "name=fad_finding_aid_discovery" -q | head -1)
docker exec finding-aids docker exec "$CONTAINER" sh -c "bundle exec rubocop app/components/homepage/"

# Rubocop on all files
CONTAINER=$(docker exec finding-aids docker ps --filter "name=fad_finding_aid_discovery" -q | head -1)
docker exec finding-aids docker exec "$CONTAINER" sh -c "bundle exec rubocop"
```

### RSpec

```bash
CONTAINER=$(docker exec finding-aids docker ps --filter "name=fad_finding_aid_discovery" -q | head -1)
docker exec finding-aids docker exec "$CONTAINER" sh -c "RAILS_ENV=test bundle exec rspec <path>"
```

Examples:
```bash
# RSpec on a single file
CONTAINER=$(docker exec finding-aids docker ps --filter "name=fad_finding_aid_discovery" -q | head -1)
docker exec finding-aids docker exec "$CONTAINER" sh -c "RAILS_ENV=test bundle exec rspec spec/services/homepage_data_spec.rb"

# RSpec on a directory
CONTAINER=$(docker exec finding-aids docker ps --filter "name=fad_finding_aid_discovery" -q | head -1)
docker exec finding-aids docker exec "$CONTAINER" sh -c "RAILS_ENV=test bundle exec rspec spec/components/homepage/"

# RSpec on all files
CONTAINER=$(docker exec finding-aids docker ps --filter "name=fad_finding_aid_discovery" -q | head -1)
docker exec finding-aids docker exec "$CONTAINER" sh -c "RAILS_ENV=test bundle exec rspec"
```

## Architecture & Design Review Skills

This project uses two complementary skills for Ruby/Rails code quality:

- **layered-rails** (`/layered-rails`) — applies layered architecture principles from "Layered Design for Ruby on Rails Applications". Use when extracting services, decomposing large modules, analyzing layer violations, or planning refactors that span controllers/services/models.
- **sandi-metz-review** (`/sandi-metz-review`) — reviews code through Sandi Metz's POODR lens: small objects, dependency injection, duck typing, composition over inheritance, tell-don't-ask.

**When to invoke:** Any time Ruby code needs structural attention — extracting a new service, refactoring a module that's grown too large, reviewing a PR with architectural decisions, or feeling like the object boundaries have drifted.

Say things like:
- `"review this with sandi metz principles"` or `"/sandi-metz-review app/services/"`
- `"extract this using layered architecture"` or `"/layered-rails:review"` for architecture review
- `"does this follow sandi metz rules?"` — the reviewer will check small objects, DI, SRP, etc.
- `"what layer should this go in?"` — runs the layered-rails spec test

Both skills work best when pointed at a specific file or directory. The sandi-metz-review skill auto-detects whether it's Ruby or JS/TS and picks the right reviewer.

## Project Structure

- `rails_app/` - Rails application code
- `rails_app/app/services/geocoding/` - Geocoding service with Cache (infrastructure) and Service (application) following layered architecture
- Docker containers: `finding-aids` (DIND), `fad_finding_aid_discovery` (Rails app)
