source "http://rubygems.org"

gem "rails", "=5.0.2"
#gem "sprockets", "2.12.3" # Latest version of sprockets 2.*. 3.* causes a failure at startup
gem "sprockets", "~> 3.4.0" # Sprockets 2 needs rack 1.x, which conflicts with rails 5
gem "mysql2", "~> 0.3.18"
gem "icu_tournament", "~> 1.9.7"
gem "icu_utils", "1.3.2"
gem "icu_ratings"
gem "icu_name", "1.2.5"
gem "whenever", :require => false
gem "redcarpet"
gem "nokogiri", "~> 1.8.1"
gem "cancancan", "~> 1.7"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "rack-mini-profiler", "=1.1.6" # latest version of 1.*. early 2.* may work too
gem "haml-rails"
gem "sass-rails", "= 5.0.5" # works with Rails 5, i.e. railties 5.0
gem "coffee-rails", "~> 4.1.0"
gem "therubyracer", platforms: :ruby
gem "uglifier"
gem "jbuilder"
gem "mime-types", "~> 2.99.3"
gem "public_suffix", "~> 1.5.3"
gem "parallel", "=1.10.0" # parallels 1.20.0 depends on Ruby 2.5

gem "nio4r", "~> 1.2" # latest version needs ruby 2.4, try this instead

group :development do
  gem "capistrano-rails", "~> 1.1"
  # Include capistrano-ssh-doctor to check for ssh errors running capistrano
  # gem 'capistrano-ssh-doctor', '~> 1.0'
  gem "wirble"
end

group :test, :development do
  gem "rspec-rails"
  gem "capybara", "=3.15.1" # latest version that works with Ruby 2.3
  gem "selenium-webdriver"
  gem "chromedriver-helper"
  gem "launchy", "=2.4.3" # latest version that works with Ruby 2.3
  gem "factory_bot_rails"
  gem "faker", "=2.2.1" # latest version that works with i18n 0.x
  gem "database_cleaner"
  gem "rubocop-rspec", "1.38.1" # latest version that works with Ruby 2.3
  gem "rubocop", "=0.81.0" # latest version that works with Ruby 2.3
  #gem "byebug"
end
