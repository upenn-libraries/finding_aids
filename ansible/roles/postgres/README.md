# Postgres

This role will deploy postgres via Docker Swarm and includes the creation of a Docker secret for the user password. If needed, the `is_development` can be set to true which will run postgres with additional logging parameters.

## Role Variables

| Variable                            | Default               | Choices             | Comments                                                         |
| ----------------------------------- | --------------------- | ------------------- | ---------------------------------------------------------------- |
| postgres.database                   | finding_aid_discovery |                     | The database name                                                |
| postgres.dev_env.log_statement      | all                   | none, ddl, mod, all | Postgres log_statement (only used if `is_development=true`)      |
| postgres.dev_env.log_connections    | on                    | on, off             | Postgres log_connections (only used if `is_development=true`)    |
| postgres.dev_env.log_disconnections | on                    | on, off             | Postgres log_disconnections (only used if `is_development=true`) |
| postgres.image.name                 | postgres              |                     | The Docker image name                                            |
| postgres.image.tag                  | 14                    |                     | The Docker image tag                                             |
| postgres.replicas                   | 1                     | 1                   | The number of replicas                                           |
| postgres.secrets.password.value     | password              |                     | The user password                                                |
| postgres.secrets.password.version   | 1                     |                     | The docker secret password version                               |
| postgres.user                       | finding_aid_discovery |                     | The user                                                         |
