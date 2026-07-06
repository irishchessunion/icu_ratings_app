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
docker compose up
```