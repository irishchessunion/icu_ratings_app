FROM docker.io/library/ruby:2.7.7-bullseye

# Ruby 2.7 reached end-of-life on 2023-03-31 (final release: 2.7.8). The newest
# Debian base the Docker Official Images project ever published for Ruby 2.7 is
# Debian 11 "bullseye"; there is no ruby:2.7-* image on bookworm/trixie. Moving
# to a newer Debian therefore requires upgrading Ruby as well.
#
# Debian 11 reached end-of-life on 2026-08-31. Its packages have been removed
# from deb.debian.org and now live only on archive.debian.org, which is frozen
# and receives no security updates. The sed below redirects apt to that archive
# so image builds keep working; without it, apt 404s on curl/wget et al.
# (Freexian's commercial ELTS can still supply Debian 11 security fixes, but it
# does not help with Ruby 2.7, which is unmaintained.)
#
# Recommended way forward:
#   1. Treat this image as frozen while Ruby 2.7 is required.
#   2. Upgrade Rails 6.1.3.2 to the latest 6.1.x first (smaller, independent
#      step), then plan the Ruby 3 / Rails 7 upgrade. Rails 6.1 is itself EOL,
#      so this is a stepping stone, not a destination.
#   3. On a maintained Ruby (3.4/3.5 at time of writing) + Rails 7.x, switch
#      FROM to ruby:<version>-bookworm (or -trixie) and delete the archive
#      workaround below. Expect sprockets 3 -> 4 changes (see Gemfile).
#   Keeping Ruby 2.7 on a newer Debian would mean compiling Ruby from source
#   (e.g. rbenv/ruby-build) on bookworm; it is not supported by the official
#   images and adds OpenSSL-version and long-term maintenance burden, so it is
#   not recommended. ruby:2.7.8-bullseye is just one patch newer on the same
#   EOL base, and Alpine-based 2.7 images are also EOL and make native gems
#   harder, so neither is a way out.
RUN sed -i 's|http://deb.debian.org/|http://archive.debian.org/|g' /etc/apt/sources.list

WORKDIR /var/apps/ratings

# Add docker-compose-wait tool
ENV WAIT_VERSION 2.7.2
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /wait
RUN chmod +x /wait

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl wget && \
    # Install node and firefox - required for unit tests
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs firefox-esr && \
    # Download geckodriver
    wget -q https://github.com/mozilla/geckodriver/releases/download/v0.32.0/geckodriver-v0.32.0-linux64.tar.gz && \
    tar -xzf geckodriver-v0.32.0-linux64.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/geckodriver && \
    rm geckodriver-v0.32.0-linux64.tar.gz && \
    # Remove apt index files as they are not needed
    rm -rf /var/lib/apt/lists/*

# Copy Gemfile first so bundle install isn't run on every build unless necessary
COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.3.25 && bundle install

# Copy app and set up config files
COPY . .
RUN cp config/database.docker.yml config/database.yml && \
    cp config/secrets.docker.yml config/secrets.yml
