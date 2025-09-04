source "http://rubygems.org"

gem "rails", "=6.1.3.2"
gem "sprockets", "~> 3.4" # sprockets 4.x needs more changes: https://stackoverflow.com/questions/58339607
gem "mysql2"
gem "icu_tournament", ">= 1.12.0"
gem "icu_utils", ">= 1.3.2"
gem "icu_ratings"
gem "icu_name", ">= 1.2.5"
gem "whenever", :require => false
gem "redcarpet"
gem "nokogiri"
gem "cancancan"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "rack-mini-profiler"
gem "haml-rails"
gem "sassc-rails"
gem "coffee-rails"
gem "therubyracer", platforms: :ruby
gem "uglifier"
gem "jbuilder"
gem "mime-types"
gem "public_suffix"
gem "parallel"

gem "nio4r"
gem "axlsx"

# Legacy gem for axlsx which requires rubyzip <= 0.9.9
gem "zip-zip"

group :development do
  gem "capistrano-rails", "~> 1.1"
  gem "ed25519"
  gem "bcrypt_pbkdf"
  # Include capistrano-ssh-doctor to check for ssh errors running capistrano
  # gem 'capistrano-ssh-doctor', '~> 1.0'
  gem "wirble"
end

group :test, :development do
  gem "rspec-rails"
  gem "capybara", "~> 3.36.0"
  gem "selenium-webdriver", "~> 4.4.0"
  gem "webdrivers"
  gem "launchy"
  gem "factory_bot_rails"
  gem "faker"
  gem "database_cleaner"
  gem "rubocop-rspec"
  gem "rubocop"
end
