require 'securerandom'
require 'stringio'
require 'ruby-gridftp'

module Datanet
  module Skel
    class FileStorage

      def initialize(path_prefix = "/mnt/auto/people", folder_name = ".datanet")
        @path_prefix = path_prefix
        @folder_name = folder_name
      end

      def store_payload(proxy, payload_stream, path = nil)
        dir = dir_path(proxy)
        file_path = path.nil? ? generate_path(proxy) : path

        gftp_client = GFTP::Client.new(proxy.proxy_payload)

        in_base_dir(gftp_client, dir) do
          upload(gftp_client, payload_stream, file_path)
        end

        file_path
      end

      def delete_file(proxy, file_path)
        gftp_client = GFTP::Client.new(proxy.proxy_payload)
        gftp_client.delete file_path do |success|
          raise Datanet::Skel::FileStorageException.new("Unable to delete #{file_path} file") unless success
        end
      end

      def get_file(proxy, file_path, &block)
        gftp_client = GFTP::Client.new(proxy.proxy_payload)
        begin
          gftp_client.get(file_path, &block)
        rescue
          raise Datanet::Skel::FileStorageException.new("Unable to read #{file_path} file")
        end
      end

      def generate_path proxy
        datanet_dir = "#{dir_path(proxy)}/#{generate_name}"
      end

      private

      def dir_path proxy
        "#{@path_prefix}/#{proxy.username}/#{@folder_name}"
      end

      def in_base_dir(gftp_client, dir, &block)
        gftp_client.exists dir do |exists|
          if exists
            yield
          else
            gftp_client.mkdir! dir do |created|
              if created
                yield
              else
                raise Datanet::Skel::FileStorageException.new "Unable to create #{dir}"
              end
            end
          end
        end
      end

      def upload(gftp_client, payload_stream, file_path)
        buf = nil
        gftp_client.put file_path do |buf_size|
          buf = payload_stream.read(buf_size) unless buf

          to_sent = buf
          buf = payload_stream.read(buf_size)

          [to_sent, !buf]
        end
      end

      # TODO insecure method - file may exist
      def generate_name
        uuid = SecureRandom.uuid
      end
    end
  end
end
