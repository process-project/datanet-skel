require 'net/sftp'
require 'securerandom'
require 'datanet-skel/sftp_connection'

module Datanet
  module Skel
    class FileStorage

      def initialize(sftp_connection, path_prefix = "/mnt/auto/people", folder_name = ".datanet")
        @conn = sftp_connection
        base_path = "#{path_prefix}/#{@conn.sftp_user}"
        @path = "#{base_path}/#{folder_name}"
        @conn.in_session do |sftp|
          prepare_datanet_dir(sftp, @path, base_path, folder_name)
        end
      end

      def store_payload(payload)
        file_path = "#{@path}/#{generate_name}"
        @conn.in_session do |sftp|
          file = sftp.file.open(file_path, "w")
          file.write(payload)
        end
        file_path
      end

      def delete_file(path)
        @conn.in_session do |sftp|
          sftp.remove!(path)
        end
      end

    private

      # TODO insecure method - file may exist
      def generate_name
        uuid = SecureRandom.uuid
      end

      def prepare_datanet_dir(sftp, path, base_path, folder_name)
        existing = false
        sftp.dir.glob(base_path, folder_name) do |entry|
          existing = true
        end
        sftp.mkdir!(path) unless existing
      end

    end
  end
end
