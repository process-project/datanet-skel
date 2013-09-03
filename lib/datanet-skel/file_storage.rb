require 'net/sftp'
require 'securerandom'
require 'datanet-skel/sftp_connection'

module Datanet
  module Skel
    class FileStorage

      def initialize(path_prefix = "/mnt/auto/people", folder_name = ".datanet")
        @path_prefix = path_prefix
        @folder_name = folder_name
      end

      def generate_path conn
        datanet_dir = "#{@path_prefix}/#{conn.sftp_user}/#{@folder_name}"
        "#{datanet_dir}/#{generate_name}"
      end

      def store_payload(conn, payload, path = nil)
        user_base = "#{@path_prefix}/#{conn.sftp_user}"
        file_path = path.nil? ? generate_path(conn) : path

        conn.in_session do |sftp|
          prepare_datanet_dir(sftp, user_base)
          file = sftp.file.open(file_path, "w")
          file.write(payload)
        end

        file_path
      end

      def delete_file(conn, file_path)
        conn.in_session do |sftp|
          sftp.remove!(file_path)
        end
      end

      CHUNK_SIZE = 100024

      def get_file(conn, file_path)
        payload = nil
        conn.in_session do |sftp|
          file = sftp.file.open(file_path, "r")
          payload = file.read(CHUNK_SIZE) # TODO - use stream, read whole file
          file.close
        end
        payload
      end

      private

      # TODO insecure method - file may exist
      def generate_name
        uuid = SecureRandom.uuid
      end

      def prepare_datanet_dir(sftp, user_base)
        existing = false
        sftp.dir.glob(user_base, @folder_name) do |entry|
          existing = true
        end
        sftp.mkdir!("#{user_base}/#{@folder_name}") unless existing
      end

    end
  end
end
