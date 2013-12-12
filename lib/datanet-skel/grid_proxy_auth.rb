require 'grid-proxy'
require "base64"

module Datanet
  module Skel
    class GridProxyAuth

      def initialize(ca_payload)
        @ca_payload = ca_payload
      end

      def authenticate(creds)
        rescue_block(false) { GP::Proxy.new(creds).valid? @ca_payload }
      end

      def username(creds)
        rescue_block(nil) { GP::Proxy.new(creds).username }
      end

      private

      def rescue_block(exception_response)
        begin
          yield
        rescue
          exception_response
        end
      end
    end
  end
end