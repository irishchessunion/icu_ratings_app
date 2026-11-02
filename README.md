ICU Ratings
===========

This is where the source code for the [ICU ratings web site](http://ratings.icu.ie) is kept.

Please see the [Wiki](https://github.com/sanichi/icu_ratings_app/wiki) for more information.

## Initial setup

Prerequisites: [Docker](https://docs.docker.com/get-docker/) and Docker Compose.

Build the docker containers:

```bash
docker compose build
```

Setup the database:

```bash
docker compose run --rm dev bundle exec rails db:migrate
```

## Running the application

Start the dev service:

```bash
docker compose up dev
```

The app will be available at http://localhost:3000.

To run it in detached mode:

```bash
docker compose up dev -d
```

To stop all the services:

```bash
docker compose down
```

### Running Tests

Run the full test suite:
```bash
docker compose run --rm test
```

Run specific tests:
```bash
docker compose run --rm test bundle exec rspec spec/models/
docker compose run --rm test bundle exec rspec spec/features/some_feature_spec.rb
```

### Useful Commands

Access Rails console:
```bash
docker compose run --rm dev bundle exec rails c
```

Run database migrations:
```bash
docker compose run --rm dev bundle exec rails db:migrate
```

Access bash inside the container:
```bash
docker compose run --rm dev bash
```

View logs:
```bash
docker compose logs -f dev
```

Rebuild after Gemfile changes:
```bash
docker compose build dev
```

### Volumes

The Docker setup uses named volumes to persist data:
- `mysql_data` - MySQL database files

To reset the database completely:
```bash
docker compose down -v
docker compose up dev
docker compose run --rm dev bundle exec rails db:migrate
```

## Devcontainer

The `.devcontainer/` configuration opens the project inside the `dev` container, with the `db` service running alongside it. The Rails server starts automatically on port 3000, and `rails db:prepare` runs when the container is first created.

Inside the devcontainer you are already in the `dev` container, so `docker` commands are not available. Run the equivalent commands in the container's terminal instead:

| Host (`docker compose ...`) | Inside the devcontainer |
|---|---|
| `docker compose run --rm dev bundle exec rails db:migrate` | `bundle exec rails db:migrate` |
| `docker compose run --rm dev bundle exec rails console` | `bundle exec rails console` |
| `docker compose run --rm dev bundle exec rails db:seed` | `bundle exec rails db:seed` |
| `docker compose run --rm test bundle exec rspec spec/models/` | `RAILS_ENV=test bundle exec rspec spec/models/` |
| `docker compose up dev` | Not needed. The server starts automatically. |
| `docker compose down -v` | Run on the host, then reopen the devcontainer. |

The database is reachable from inside the devcontainer as `db:3306`, so the port override in "Connecting with a database client" is only needed for clients running on the host. To load the test schema, run `RAILS_ENV=test bundle exec rails db:schema:load`.

## Development database

### What is created

- The `db` service in `docker-compose.yml` runs MySQL 8.0.42. Its data is kept in the `mysql_data` volume.
- Credentials: user `ratings`, password `password` (root password is also `password`). The database is not published to the host, so it is only reachable from other containers as `db:3306`.
- `init/01.sql` creates the `ratings_dev` and `ratings_test` databases. It only runs when the MySQL volume is first created.
- `config/database.docker.yml` is the Rails database config. The Dockerfile copies it to `config/database.yml`, and the devcontainer mounts it there.
- The schema is built by `rails db:migrate` from `db/migrate/`. `db/schema.rb` is the snapshot of the current schema.

### What data is loaded

- `db:migrate` imports historical rating data from `db/data/*.csv` (about 74,000 rows across `old_tournaments`, `old_ratings`, `old_rating_histories` and `icu_ratings`). This uses `LOAD DATA LOCAL INFILE`, which the `db` service enables with `--local-infile=1`.
- There are no current players, users, tournaments or ratings after migration.
- The sample data in `db/seeds.rb` is disabled (`seed_sample_data = false`). See below for enabling it.
- Live data lives in the ICU website database, configured as `www_db` in `config/secrets.docker.yml`. Compose does not provide that database, so the ICU player sync and user pulls will not work locally.

### Logging in locally

There are no users after migration. Choose one of these:

**Option 1: enable the sample seeds.** Set `seed_sample_data = true` in `db/seeds.rb`, then run:

```bash
docker compose run --rm dev bundle exec rails db:seed
```

This creates sample users including `admin@icu.ie` / `password0` (admin role). Other sample users, such as `alice@example.com` / `password1`, are admins or members. Set `seed_sample_data` back to `false` before committing.

**Option 2: create a user in the Rails console.** A user must point at an ICU player, so create the player first:

```bash
docker compose run --rm dev bundle exec rails console
```

```ruby
p = IcuPlayer.create!(first_name: "Test", last_name: "Admin", gender: "M", dob: "2000-01-01", joined: "2020-01-01", deceased: false, club: "Dublin", fed: "IRL", title: "FM")
User.create!(email: "admin@example.com", password: "password0", role: "admin", status: "ok", expiry: "2035-01-01", icu_id: p.id)
```

Keep `status: "ok"` and a future `expiry`. Otherwise login is refused. Passwords created this way are stored unsalted, which is fine for local testing.

Login attempts also try to pull the account from the ICU website database when the password check fails or the account is inactive or expired. Without that database the pull fails, and the failure is recorded as a `Failure` record rather than blocking login. A user set up as above does not trigger a pull.

### Connecting with a database client (e.g. VS Code)

The database is not published to the host by default. To connect from a client on your machine, create a `docker-compose.override.yml` file in the repository root. Docker Compose reads it automatically:

```yaml
services:
  db:
    ports:
      - "127.0.0.1:3306:3306"
```

Restart with `docker compose up -d db`, then connect with:

- Host: `127.0.0.1`
- Port: `3306`
- User: `ratings`
- Password: `password`
- Database: `ratings_dev` (or `ratings_test`)

Keep this override file uncommitted. Add it to `.gitignore` if it isn't already there.

Alternatively, open the project in the dev container, where the database is reachable as `db:3306`. A database extension must run inside the container, so add it to `customizations.vscode.extensions` in `.devcontainer/devcontainer.json`.

### Resetting the database

See [Volumes](#volumes) above. Resetting wipes all data, and the migrations then reload the historical CSV data, so it takes a while.