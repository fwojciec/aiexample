# Database Setup Guide

## Overview

This project uses PostgreSQL for data persistence. Development and test databases are managed via Docker Compose for local development. Production uses Google Cloud SQL.

## Local Development with Docker

Docker Compose manages PostgreSQL:
1. PostgreSQL runs on the standard port 5432
2. Both `bookscanner` and `bookscanner_test` databases are created automatically
3. Start with `make dev-up`, stop with `make dev-down`

Docker provides a consistent development environment across all platforms.

## Connection Strings

### Development Database
```
postgres://bookscanner:bookscanner@localhost:5432/bookscanner?sslmode=disable
```

### Test Database
```
postgres://bookscanner:bookscanner@localhost:5432/bookscanner_test?sslmode=disable
```

### Environment Variables

The project uses two database-related environment variables:
- `DATABASE_URL` - Used for the main application database
- `TEST_DATABASE_URL` - Used specifically for integration tests

Both should be defined in your `.env` file for proper operation.

## Running Tests

### Setup Test Environment

Ensure Docker is running, then:

```bash
# Start PostgreSQL
make dev-up

# Run integration tests
make test-integration
```

The test database is created automatically by Docker on startup.

### Running Specific Tests

To run specific PostgreSQL tests:
```bash
make test-postgres TEST_ARGS="-run TestPostgresBookService_CreateBook"
```

### PostgreSQL Management

Docker Compose handles PostgreSQL:

```bash
# Start PostgreSQL
make dev-up

# Check status
docker compose ps

# View logs
make dev-logs

# Stop PostgreSQL
make dev-down

# Reset database (removes volumes)
make dev-reset
```

## Important Notes

1. **Docker-Managed PostgreSQL**: We use Docker Compose to manage PostgreSQL. Start it with `make dev-up`.

2. **Test Isolation**: Each test creates its own schema for complete isolation. This allows tests to run in parallel without conflicts.

3. **Environment Variables**: The `.envrc` file sets the correct `DATABASE_URL` and `TEST_DATABASE_URL`. Use `direnv allow` to load them.

4. **Connection Errors**: If you see "password authentication failed", ensure:
   - Docker is running and PostgreSQL is up: `docker compose ps`
   - You're using port 5432 in your connection string
   - Environment variables are loaded: `echo $DATABASE_URL`
   - The test database exists (created automatically by Docker)

## Troubleshooting

### Common Issues

1. **Port 5432 already in use**
   - Check if PostgreSQL is already running: `docker compose ps`
   - If another PostgreSQL is using it: `lsof -i :5432`
   - Stop conflicting process or change port in docker-compose.yml

2. **PostgreSQL not starting**
   - Ensure Docker is running
   - Check Docker logs: `make dev-logs`
   - Try restart: `make dev-down && make dev-up`

3. **Tests failing with connection errors**
   - Verify PostgreSQL is running: `docker compose ps`
   - Check you're using port 5432 in connection strings
   - Ensure databases exist: `docker compose exec postgres psql -U bookscanner -l`
   - Verify connection: `docker compose exec postgres psql -U bookscanner -d bookscanner_test -c '\dt'`

4. **"Database does not exist" errors**
   - The Docker init script creates databases automatically
   - If needed, reset: `make dev-reset && make dev-up`