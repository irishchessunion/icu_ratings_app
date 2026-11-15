require File.expand_path("../boot", __FILE__)
require "yaml"
require "logger"
require "rails/all"

Bundler.require(*Rails.groups)

module Ratings
  class Application < Rails::Application
    # Express preference for double quoted attributes (single quoted is HAML's default).
    Haml::Template.options[:attr_wrapper] = '"'

    # Custom directories with classes and modules you want to be autoloadable.
    # Rails 7.0+ freezes autoload_paths, so use explicit requires instead.
    require Rails.root.join("lib/icu/util/pagination")
    require Rails.root.join("lib/icu/util/model")
    require Rails.root.join("lib/icu/ratings_app")
    require Rails.root.join("lib/icu/rating_run")
    require Rails.root.join("lib/icu/export")
    require Rails.root.join("lib/icu/error")
    require Rails.root.join("lib/icu/database")
    require Rails.root.join("lib/fide/download")
    require Rails.root.join("lib/fide/exported_player")

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Rails 7.0: use the new connection handling (required for Rails 7.1+).
    config.active_record.legacy_connection_handling = false

    # no-reply@icu.ie used to cause an error when we were with register365.
    config.action_mailer.default_options = { from: "NO-REPLY@icu.ie" }
  end
end
