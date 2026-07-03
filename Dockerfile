FROM ruby:2.7.7-bullseye

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
