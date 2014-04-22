require 'grid-proxy'
require "base64"

module Datanet
  module Skel
    class GridProxyAuth

      def initialize(ca_payload, crl_payload = nil)
        @ca_payload = ca_payload
        @crl_payload = crl_payload
      end

      def authenticate(creds)
        #we need to read crl each time, if it desn't exist skip it altogether
        rescue_block(false) { GP::Proxy.new(creds).valid?(@ca_payload, crl_file) }
      end

      def username(creds)
        rescue_block(nil) { GP::Proxy.new(creds).username }
      end

      private

      def crl_file
        crl_location? ? File.read(@crl_location) : nil
      end

      def crl_location?
        @crl_location && File.exists?(@crl_location)
      end

      def rescue_block(exception_response)
        begin
          yield
        rescue Exception => e
          API.logger.debug "Wrong proxy: #{e}"
          exception_response
        end
      end
    end
  end
end