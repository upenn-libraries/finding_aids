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

## Project Structure

- `rails_app/` - Rails application code
- Docker containers: `finding-aids` (DIND), `fad_finding_aid_discovery` (Rails app)
