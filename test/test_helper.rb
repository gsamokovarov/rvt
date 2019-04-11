require 'simplecov'
SimpleCov.start 'rails'

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

require 'pty'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# rails-dom-testing assertions doesn't like the JavaScript we inject into the page.
module SilenceRailsDomTesting
  def assert_select(*)
    silence_warnings { super }
  end
end

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end

require 'mocha/minitest'

require 'byebug'
