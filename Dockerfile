FROM ruby:2.7.7-buster

# set working directory in docker image
WORKDIR /var/apps/ratings

# Add docker-compose-wait tool -------------------
ENV WAIT_VERSION 2.7.2
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /wait
RUN chmod +x /wait

# Copy settings
ADD . /var/apps/ratings/
RUN cp config/database.yml.docker config/database.yml

# Install Node
RUN apt-get -y update
RUN apt-get -y install curl

RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs firefox-esr

# Install geckodriver
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.32.0/geckodriver-v0.32.0-linux64.tar.gz
RUN tar -xzvf geckodriver-v0.32.0-linux64.tar.gz -C /usr/local/bin
RUN chmod +x /usr/local/bin/geckodriver

RUN gem install bundler:2.3.25
RUN bundle update

