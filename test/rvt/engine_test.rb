require 'test_helper'

module RVT
  class EngineTest < ActiveSupport::TestCase
    test 'custom default_mount_path' do
      new_uninitialized_app do |app|
        app.config.rvt.default_mount_path = '/shell'
        app.initialize!

        assert app.routes.named_routes['rvt'].path.match('/shell')
      end
    end

    test 'disabling automounting' do
      new_uninitialized_app do |app|
        app.config.rvt.automount = false
        app.initialize!

        assert_not app.routes.named_routes['rvt']
      end
    end

    test 'blank commands are expanded to the rails console' do
      new_uninitialized_app do |app|
        app.config.rvt.command = ' '
        app.initialize!

        expected_path = Rails.root.join('bin/rails console').to_s
        assert_equal expected_path, app.config.rvt.command
      end
    end

    test 'present commands are not processed' do
      new_uninitialized_app do |app|
        app.config.rvt.command = '/bin/login'
        app.initialize!

        assert_equal '/bin/login', app.config.rvt.command
      end
    end

    test 'whitelisted ips are courced to IPAddr' do
      new_uninitialized_app do |app|
        app.config.rvt.whitelisted_ips = '127.0.0.1'
        app.initialize!

        assert_equal [ IPAddr.new('127.0.0.1') ], app.config.rvt.whitelisted_ips
      end
    end

    test 'whitelisted ips with IPv6 format as default' do
      new_uninitialized_app do |app|
        app.config.rvt.whitelisted_ips = [ '127.0.0.1', '::1' ]
        app.initialize!

        assert_equal [ IPAddr.new('127.0.0.1'), IPAddr.new('::1') ], app.config.rvt.whitelisted_ips
      end
    end

    test 'whitelisted ips are normalized and unique IPAddr' do
      new_uninitialized_app do |app|
        app.config.rvt.whitelisted_ips = [ '127.0.0.1', '127.0.0.1', nil, '', ' ' ]
        app.initialize!

        assert_equal [ IPAddr.new('127.0.0.1') ], app.config.rvt.whitelisted_ips
      end
    end

    test 'whitelisted_ips.include? coerces to IPAddr' do
      new_uninitialized_app do |app|
        app.config.rvt.whitelisted_ips = '127.0.0.1'
        app.initialize!

        assert app.config.rvt.whitelisted_ips.include?('127.0.0.1')
      end
    end

    test 'whitelisted_ips.include? works with IPAddr' do
      new_uninitialized_app do |app|
        app.config.rvt.whitelisted_ips = '127.0.0.1'
        app.initialize!

        assert app.config.rvt.whitelisted_ips.include?(IPAddr.new('127.0.0.1'))
      end
    end

    test 'whitelist whole networks' do
      new_uninitialized_app do |app|
        app.config.rvt.whitelisted_ips = '172.16.0.0/12'
        app.initialize!

        1.upto(255).each do |n|
          assert_includes app.config.rvt.whitelisted_ips, "172.16.0.#{n}"
        end
      end
    end

    test 'whitelist multiple networks' do
      new_uninitialized_app do |app|
        app.config.rvt.whitelisted_ips = %w( 172.16.0.0/12 192.168.0.0/16 )
        app.initialize!

        1.upto(255).each do |n|
          assert_includes app.config.rvt.whitelisted_ips, "172.16.0.#{n}"
          assert_includes app.config.rvt.whitelisted_ips, "192.168.0.#{n}"
        end
      end
    end

    private

      def new_uninitialized_app(root = File.expand_path('../../dummy', __FILE__))
        skip if Rails::VERSION::MAJOR == 3

        old_app = Rails.application

        FileUtils.mkdir_p(root)
        Dir.chdir(root) do
          Rails.application = nil

          app = Class.new(Rails::Application)
          app.config.eager_load = false
          app.config.time_zone = 'UTC'
          app.config.middleware ||= Rails::Configuration::MiddlewareStackProxy.new
          app.config.active_support.deprecation = :notify

          yield app
        end
      ensure
        Rails.application = old_app
      end

      def teardown_fixtures(*)
        super
      rescue
        # This is nasty hack to prevent a connection to the database in JRuby's
        # activerecord-jdbcsqlite3-adapter. We don't really require a database
        # connection, for the tests to run.
        #
        # The sad thing is that I couldn't figure out why does it only happens
        # on activerecord-jdbcsqlite3-adapter and how to actually prevent it,
        # rather than work-around it.
      end
  end
end
