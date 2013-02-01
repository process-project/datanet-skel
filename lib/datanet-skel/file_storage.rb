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

      def generate_path
        "#{@path}/#{generate_name}"
      end

      def store_payload(payload, path = nil)
        file_path = generate_path if path.nil?
        @conn.in_session do |sftp|
          file = sftp.file.open(file_path, "w")
          file.write(payload)
        end
        file_path
      end

      def delete_file(file_path)
        @conn.in_session do |sftp|
          sftp.remove!(file_path)
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
