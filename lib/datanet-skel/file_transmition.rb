module Datanet
  module Skel
    class FileTransmition

      attr_accessor :proxy_payload, :files

      def initialize(proxy_payload, files)
        @proxy_payload = proxy_payload
        @files = files
      end
    end
  end
end

