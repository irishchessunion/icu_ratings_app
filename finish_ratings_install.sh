#!/usr/bin/env bash

echo "Finishing install of ratings site with version $1"
cd /var/apps/ratings/releases/$1
GIT_HASH=`git log --pretty=format:'%h' -n 1`

echo "Running bundle install"
bin/bundle install --path /var/apps/ratings/shared/bundle --without development test --deployment
echo "Running assets:precompile"
bin/bundle exec rake assets:precompile

cp /var/apps/ratings/releases/$1/public/assets/manifest* /var/apps/ratings/releases/$1/assets_manifest_backup
cp /var/apps/ratings/releases/$1/app/assets/images/images/* /var/apps/ratings/releases/$1/public/assets/images
echo "Running db:migrate"
RAILS_ENV=production bin/bundle exec rake db:migrate
echo "Setting up cron jobs"
RAILS_ENV=production bin/bundle exec whenever --update-crontab icu_ratings_app --set environment=production --roles=web,app,db
echo "linking release to releases/current"
ln -s /var/apps/ratings/releases/$1 /var/apps/ratings/releases/current
echo "Moving releases/current to /var/apps/ratings"
mv /var/apps/ratings/releases/current /var/apps/ratings

echo "Branch master (at $GIT_HASH) deployed as release $1 by `whoami`" >> /var/apps/ratings/revisions.log
echo "Restarting ratings app"
touch /var/apps/ratings/releases/$1/tmp/restart.txt
