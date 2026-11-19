require File.expand_path("../boot", __FILE__)
require "yaml"
require "logger"
require "rails/all"

Bundler.require(*Rails.groups)

module Ratings
  class Application < Rails::Application
    # Rails 7.2 removed Rails.application.secrets. This shim adds it back via config_for
    # so the rest of the codebase keeps working until a proper migration to credentials.
    # config_for returns nil when the current environment has no section in secrets.yml
    # (e.g. staging on a host that only defines production/development), so fall back
    # to an empty OrderedOptions to keep booting instead of crashing.
    config.secrets = config_for(:secrets) || ActiveSupport::OrderedOptions.new
    config.secret_key_base = config.secrets[:secret_key_base] if config.secrets.respond_to?(:[]) && config.secrets[:secret_key_base].present?
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

    # Rails 7.1: opt into the new cache format (silences deprecation warning).
    config.active_support.cache_format_version = 7.0

    # Rails 7.1: ActionMailer railtie freezes preview_paths; set to empty to avoid FrozenError.
    # The preview path is already in autoload_paths by default.
    config.action_mailer.preview_paths = []

    # no-reply@icu.ie used to cause an error when we were with register365.
    config.action_mailer.default_options = { from: "NO-REPLY@icu.ie" }

    def secrets
      config.secrets
    end
  end
end
