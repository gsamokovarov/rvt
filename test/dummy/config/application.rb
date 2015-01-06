require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)
require 'rvt'

module Dummy
  class Application < Rails::Application
    # Automatically mount the console to tests the terminal side as well.
    config.rvt.automount = true

    if ENV['LONG_POLLING']
      # You have to explicitly enable the concurrency, as in development mode,
      # the falsy config.cache_classes implies no concurrency support.
      #
      # The concurrency is enabled by removing the Rack::Lock middleware, which
      # wraps each request in a mutex, effectively making the request handling
      # synchronous.
      config.allow_concurrency = true

      # For long-polling 45 seconds timeout seems reasonable.
      config.rvt.timeout = 45.seconds
    end

    config.rvt.style.colors =
      if ENV['SOLARIZED_LIGHT']
        'solarized_light'
      elsif ENV['SOLARIZED_DARK']
        'solarized_dark'
      elsif ENV['TANGO']
        'tango'
      elsif ENV['XTERM']
        'xterm'
      elsif ENV['MONOKAI']
        'monokai'
      else
        'light'
      end

    # The test order can be random after 4.1.
    config.active_support.test_order = :random
  end
end
