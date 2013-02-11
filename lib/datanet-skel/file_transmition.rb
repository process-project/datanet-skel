module Datanet
  module Skel
    class FileTransmition

      attr_accessor :sftp_connection, :files

      def initialize(sftp_connection, files)
        @sftp_connection = sftp_connection
        @files = files
      end

    end
  end
end

