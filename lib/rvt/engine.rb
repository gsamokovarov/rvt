# frozen_string_literal: true

require 'ipaddr'
require 'active_support/core_ext/numeric/time'
require 'rails/engine'

require 'active_model'
require 'sprockets/rails'

module RVT
  class Engine < ::Rails::Engine
    isolate_namespace RVT

    config.rvt = ActiveSupport::OrderedOptions.new.tap do |c|
      c.automount          = true
      c.command            = nil
      c.default_mount_path = '/console'
      c.timeout            = 0.seconds
      c.process_timeout    = 5.minutes
      c.term               = 'xterm-color'
      c.whitelisted_ips    = ['127.0.0.1', '::1']
      c.allowed_envs       = %w(test development)
      c.username           = ''
      c.password           = ''

      # Rails 5 defaults on Puma as a web server, so we can be long polling by
      # default.
      c.timeout ||= 45.seconds if ::Rails.version >= '5.0.0'

      c.style = ActiveSupport::OrderedOptions.new.tap do |s|
        s.font = 'large Menlo, DejaVu Sans Mono, Liberation Mono, monospace'
      end
    end

    initializer 'rvt.add_default_route' do |app|
      # While we don't need the route in the test environment, we define it
      # there as well, so we can easily test it.
      if config.rvt.automount && Array(config.rvt.allowed_envs).include?(Rails.env)
        app.routes.append do
          mount RVT::Engine => app.config.rvt.default_mount_path
        end
      end
    end

    initializer 'rvt.process_whitelisted_ips' do
      config.rvt.tap do |c|
        # Ensure that it is an array of IPAddr instances and it is defaulted to
        # 127.0.0.1 if not present. Only unique entries are left in the end.
        c.whitelisted_ips = Array(c.whitelisted_ips).map { |ip|
          if ip.is_a?(IPAddr)
            ip
          else
            IPAddr.new(ip.presence || '127.0.0.1')
          end
        }.uniq

        # IPAddr instances can cover whole networks, so simplify the #include?
        # check for the most common case.
        def (c.whitelisted_ips).include?(ip)
          if ip.is_a?(IPAddr)
            super
          else
            any? { |net| net.include?(ip.to_s) }
          end
        end
      end
    end

    initializer 'rvt.process_command' do
      config.rvt.tap do |c|
        # +Rails.root+ is not available while we set the default values of the
        # other options. Default it during initialization.

        # Not all people created their Rails 4 applications with the Rails 4
        # generator, so bin/rails may not be available.
        if c.command.blank?
          local_rails = Rails.root.join('bin/rails')
          timeout_path = `which timeout`.chomp
          timeout_suffix =
            if timeout_path.present? && c.process_timeout.present?
              "#{timeout_path} #{c.process_timeout.to_i}"
            else
              ''
            end
          c.command = "#{timeout_suffix} #{local_rails.executable? ? local_rails : 'rails'} console"
        end
      end
    end
  end
end
