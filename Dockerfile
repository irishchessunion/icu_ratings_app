# Dockerfile for running ICU ratings app containerized

# To run this on ubuntu 20.04

# - install docker https://linuxize.com/post/how-to-install-and-use-docker-on-ubuntu-20-04/
# - xhost +local:docker # allow docker to draw to your X display
# - run a mysql server locally with a ratings_development and a ratings_test database (can be empty),
#       and create a user that has privileges for those databases
# - add a database.yml and a secrets.yml file in config/
#   - these can be based on database.yml.example and secrets.yml.example, with some changes:
#       - database username and password need to match what you picked above
#       - database socket for all envs should be /tmp/mysqld.sock
#       - in secrets.yml, change Hasher to "Digest::MD5.hexdigest(Digest::MD5.hexdigest(salt[0,15] + pass + salt[17,15]))"
# - docker build -t ratingstest . # build the docker image, based on this file.
# This takes a long time the first time you do it, but shorter thereafter as it does some caching.
# - docker run -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /run/mysqld/mysqld.sock:/tmp/mysqld.sock -it ratingstest bash

# this gives you a bash shell in your docker image, with mysql and X11 forwarded to sockets on your host machine
# - rspec spec/features/failures_spec.rb # run a tiny section of the test suite (4 tests) that exercises the important moving parts (firefox and mysql)
# - if that works, rspec spec/ # run all the tests, takes me 10-15 min


# 16.04 is the latest version where Brightbox supports Ruby 2.2
# 18.04 is probably possible using rvm to install instead
FROM ubuntu:16.04

# set working directory in docker image
WORKDIR /var/apps/ratings

# run this first because it's needed for apt-add-repository
RUN apt-get update && apt-get install -y software-properties-common

RUN apt-add-repository ppa:brightbox/ruby-ng

RUN apt-get update && apt-get install -y \
    less \
    curl \
    ruby2.6 \
    ruby2.6-dev \
    build-essential \
    zlib1g-dev \
    libmysqlclient-dev \
    tzdata \
    mariadb-client-10.0 \
    wget \
    firefox \
    xauth \
    nodejs \
    vim

# install geckodriver
RUN wget -q https://github.com/mozilla/geckodriver/releases/download/v0.29.1/geckodriver-v0.29.1-linux64.tar.gz
RUN tar -x geckodriver -zf geckodriver-v0.29.1-linux64.tar.gz -O > /usr/bin/geckodriver
RUN chmod +x /usr/bin/geckodriver

# copy files from directory icu_ratings_app in host
# this needs to be a git clone of icu_ratings_app, plus:
# - database.yml
# - secrets.yml
# Do this as late as possible in the dockerfile, because this is going to change
# more often than the build dependencies
ADD . /var/apps/ratings/

RUN gem install bundler:1.17.3 --no-document
RUN bundle update
