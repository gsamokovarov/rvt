module RVT
  class ApplicationController < ActionController::Base
    before_action :prevent_unauthorized_requests!

    private

    def prevent_unauthorized_requests!
      remote_ip = GetSecureIp.new(request, RVT.config.whitelisted_ips).to_s

      unless remote_ip.in?(RVT.config.whitelisted_ips)
        render nothing: true, status: :unauthorized
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
