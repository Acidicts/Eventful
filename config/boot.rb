ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# load dotenv early so environment variables in .env are available to
# configuration (including omniauth).  dotenv is pulled in as a dependency
# of other gems, so we require it explicitly here if it's present.
begin
  require "dotenv"
  Dotenv.load(File.expand_path("../.env", __dir__))
rescue LoadError
  # dotenv not installed; ignore
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
