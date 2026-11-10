ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
require "logger"
require "bundler/setup" # Set up gems listed in the Gemfile.
