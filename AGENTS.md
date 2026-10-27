# AGENTS.md

This file provides guidance to Claude, Codex, OpenCode and other AI agents when working with code in this repository.

## Project

Source for the Irish Chess Union's ratings web site (ratings.icu.ie) — a Rails **6.1.3.2** app. See the [wiki](https://github.com/irishchessunion/icu_ratings_app/wiki) and [legacy_wiki](https://github.com/sanichi/icu_ratings_app/wiki) for server setup/maintenance information beyond initial dev setup. Bundler is **2.3.25**; `.tool-versions` specifies Ruby **2.7.6**, while Docker uses **2.7.7** and MySQL **8.0.42**.

Views are written in **HAML** (`.html.haml`), not ERB — use HAML syntax/whitespace-significant indentation when editing or adding views. Tests are written in **RSpec** (models, routing, helpers, presenters, mailers, and Capybara/Selenium feature specs).

## Docker

The documented Docker Compose setup is:

```bash
# One-time setup (preserve existing local configs)
test -f config/database.yml || cp config/database.docker.yml config/database.yml
test -f config/secrets.yml || cp config/secrets.docker.yml config/secrets.yml
docker compose build
docker compose run --rm dev bundle exec rails db:migrate

# Run the app (dev + MySQL) at http://localhost:3000
docker compose up dev          # or add -d for detached
docker compose down            # stop services

# Empty test database: load the current schema
docker compose run --rm --build -e RAILS_ENV=test test bundle exec rails db:schema:load

# Tests (--build keeps the test image current)
docker compose run --rm --build test                                                       # full suite
docker compose run --rm --build test bundle exec rspec spec/models/                        # a directory
docker compose run --rm --build test bundle exec rspec spec/models/tournament_spec.rb:11    # single test by line

# Console / migrations / shell
docker compose run --rm dev bundle exec rails console
docker compose run --rm dev bundle exec rails db:migrate
docker compose run --rm dev bash

docker compose logs -f dev
docker compose build dev       # rebuild after Gemfile/lockfile changes
```

Docker notes:
- `dev` bind-mounts the checkout over the image, hiding the config files created by the Dockerfile. Create missing `config/database.yml` and `config/secrets.yml` from the Docker templates above; both local files are gitignored.
- The `test` service has **no source bind mount**: rebuild it after edits or it tests stale code. Keep `--build` in test commands.
- `init/01.sql` creates `ratings_dev` and `ratings_test` on first MySQL volume initialization. The database service is reachable as `db` inside Compose and has no published host port.

Tests use RSpec + Capybara/Selenium (feature specs) with `database_cleaner` (transaction strategy normally, truncation for `js: true` and `truncation: true` specs — see `spec/rails_helper.rb`). Transactional fixtures are disabled; retain tags needed for committed data. JS specs use **headless Firefox + geckodriver**, served by WEBrick; the Dockerfile installs the browser dependencies.

Specs require `rails_helper`. Shared helpers include `login(user_or_role)`, `test_tournament(filename, user_id)`, and `load_icu_players_for`. Tournament input files are in `spec/files/`; player/rating data is in `spec/factories/*.yml`. `User.pulls_disabled = true` prevents automatic pulls from the separate ICU website database during tests.

RuboCop gems are present, but there is no checked-in lint configuration.

## Architecture

### Auth & authorization
Auth is hand-rolled — `User` stores `password`/`salt` directly and implements `authenticate!`/`password_ok?`; `SessionsHelper` provides the current user. Authorization is role-based via CanCanCan: each user has a single role, and `User#role?` means **at least** the requested role. Preserve the ordering of `User::ROLES` (`member reporter organiser officer admin`). Permission logic is centralized in `app/models/ability.rb` (`Ability#initialize`, plus shared locked/unlocked rules). When adding a feature that needs permission checks, extend `Ability` rather than sprinkling role checks through controllers. Locked tournaments restrict edits even for admins.

### Public vs admin surface
`config/routes.rb` defines a public-facing resource set (mostly `index`/`show`, plus tournament creation) and a parallel `namespace :admin` with fuller CRUD for the same models. Controllers/views mirror this split (`app/controllers/admin/...`, `app/views/admin/...`). When adding or changing a resource, check both sides.

### Style Guide / CSS / Theme
Existing application views are legacy and use nested tables for layout. Preserve their existing markup, styling, and conventions during maintenance. Apply Bootstrap and the following guidance only to **newly built views or views being rebuilt**, rather than modernizing legacy views as part of unrelated changes.

Legacy views continue to use `app/assets/stylesheets/main.sass.erb`, imported after Bootstrap. Reuse its shared Sass variables when maintaining legacy styles; background/content colours vary by Rails environment.

- Check existing project CSS and Bootstrap **5.3.8** classes and components before creating new classes or rules. Refer to the [Bootstrap 5.3 documentation](https://getbootstrap.com/docs/5.3/) if needed.
- Add custom CSS and rules to `app/assets/stylesheets/application.scss` only very conservatively when existing project or framework styles cannot meet the requirement. Ensure any new styles do not affect legacy views or vice-versa. Avoid adding new `!important` flags.
- Inherit typography. Override `font-size` only when necessary, using `em` so it scales with inherited values.
- Use semantic HTML for page structure. Reserve tables for tabular data; prefer widely supported elements that match the content's meaning (`article`, `header`, `footer`, `nav`, lists, etc.) over layout tables or nested div wrappers.
- New custom CSS for non-legacy views should be mobile-first: use base styles for small screens and `min-width` media queries for larger-screen overrides. Follow Bootstrap 5.3 breakpoints and conventions.
- Keep CSS selectors structural. Prefer a component class with child selectors, e.g. `.results-item > header` and `.results-item > footer`, rather than `.results-item-header` and `.results-item-footer`. Add child classes only when needed to distinguish their purpose or behaviour.

### Hotwire (Turbo & Stimulus)
`turbo-rails` (~> 1.5) and `stimulus-rails` (~> 1.3) are loaded from `app/views/layouts/_head.html.haml` as two ES module scripts: `turbo` standalone, plus `hotwire.js` (a Sprockets bundle containing Stimulus and boot). Keep these as separate module scripts.

Turbo Drive is **globally disabled** in the bundle (`Turbo.session.drive = false`), so all links/forms keep their current full-page/jQuery-UJS behaviour until a feature explicitly opts in. Stimulus is started in the bundle and exposed as `window.Stimulus`.

**All new interactive features should use Stimulus controllers.**
Define and register controllers in additional files required into `app/assets/javascripts/hotwire.js`.
Migrate existing features to Hotwire page-by-page only when requested rather than removing the legacy `jquery_ujs` behaviour.

Assets use **Sprockets 3**, jQuery UJS, and CoffeeScript/Sass. The JS manifest is `app/assets/javascripts/application.js`; additional standalone JS bundles must be listed in `config/initializers/assets.rb` for production precompilation.

### Shared model behaviour (`lib/icu/util/`)
Models extend `ICU::Util::Pagination` for custom pagination. `Model.paginate(matches, path, params)` returns an `ICU::Util::Paginator`, used directly in views - search methods commonly return this wrapper rather than an Active Record relation.

`config/application.rb` adds `lib/` to the autoload paths.

### Tournament imports & rating runs
`Upload#extract` parses files through the **`icu_tournament` gem**, then `Tournament.build_from_icut` builds unsaved tournament/player/result records. `Admin::UploadsController#create` handles saving them.
Rating orchestration lives in `Tournament`/`Player`.
The rating calculation engine is `ICU::RatedTournament` from the **`icu_ratings` gem**.

Batch runs use filesystem flags and Whenever cron: `RatingRun` writes `tmp/<environment>_rating_run`; `config/schedule.rb` renames it with a trailing `_` before invoking `rating:run` (`lib/tasks/rate.rake` → `ICU::RatingRun`).
Compose starts no cron worker, so batch runs wait without that handoff.
Tests always use the trailing-underscore flag.

### ICU website synchronization
`lib/icu/database.rb` synchronizes with the sister website's database through `Rails.application.secrets.www_db`; this is a separate connection from `config/database.yml` and is not provisioned by Compose.
Scheduled sync/export tasks are defined in `config/schedule.rb` and `lib/tasks/`

### Legacy data
Historical migrations import `db/data/*.csv` using `LOAD DATA LOCAL INFILE`; Compose enables MySQL's `local-infile` for these imports.
For a fresh test database, load `db/schema.rb` with `db:schema:load` instead of replaying the data migrations.
