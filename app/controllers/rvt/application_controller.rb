module RVT
  class ApplicationController < ActionController::Base
    # Rails 5.2 has this by default. Skip it, as we don't need it for RVT.
    skip_before_action :verify_authenticity_token, raise: false

    before_action :prevent_unauthorized_requests!

    http_basic_authenticate_with name: RVT.config.username, password: RVT.config.password if RVT.config.username.present? && RVT.config.password.present?

    private

    def prevent_unauthorized_requests!
      return if RVT.config.whitelisted_ips.blank?

      remote_ip = GetSecureIp.new(request, RVT.config.whitelisted_ips).to_s

      unless remote_ip.in?(RVT.config.whitelisted_ips)
        head :unauthorized
      end
    end

    class GetSecureIp < ActionDispatch::RemoteIp::GetIp
      def initialize(req, proxies)
        # After rails/rails@07b2ff0 ActionDispatch::RemoteIp::GetIp initializes
        # with a ActionDispatch::Request object instead of plain Rack
        # environment hash. Keep both @req and @env here, so we don't if/else
        # on Rails versions.
        @req      = req
        @env      = req.env
        @check_ip = true
        @proxies  = proxies
      end

      def filter_proxies(ips)
        ips.reject { |ip| @proxies.include?(ip) }
      end
    end
  end
end
