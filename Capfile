# Load DSL and setup stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# include git SCM
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Includes tasks from other gems
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'whenever/capistrano'
# Use ssh_doctor to check if you can reach the machine and run commands on it.
# require 'capistrano/ssh_doctor'

# Load custom tasks from `lib/capistrano/tasks'
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
