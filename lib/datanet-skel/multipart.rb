require 'rack/utils'
require 'json'

module Datanet
  module Skel
    class Multipart

      # files - a Hash containing form input field name as a key
      #         and Hash { :filename => filename, :payload => payload } as a value
      # metadata - metadata as a String

      attr_accessor :files, :metadata

      def initialize(env)
        @env = env
        @files = Hash.new
        @fields = Hash.new
        build_object(Rack::Utils::Multipart.parse_multipart(env))
        raise "Metadata not specified" if @metadata.nil?
      end

      def build_object(params)
        unless params["metadata"] == nil
          value = params["metadata"]
          if value.instance_of? String
            set_metadata value
          else
            raise "Uploaded metadata file has to conform application/json type" unless value[:type] == "application/json"
            raise "Uploaded metadata file is empty" unless value.has_key? :tempfile
            set_metadata value[:tempfile].read
          end
        end
        params.each do |key, value|
          next if key == "metadata"
          if value.instance_of? Hash
            payload = value.has_key?(:tempfile) ? value[:tempfile].read : ""
            filename = value.has_key?(:filename) ? value[:filename] : ""
            set_file key, { :filename => filename, :payload => payload }
          elsif value.instance_of? String
            set_field key, value
          end
        end
        process_fields
      end

      def process_fields
        unless @fields.empty?
          set_metadata @fields.to_json
        end
      end

      def set_field key, value
        raise "Multiple specification of the property #{key} " unless @fields[key].nil?
        @fields[key] = value
      end

      def set_metadata metadata
        raise "Multiple specification of metadata" unless @metadata.nil?
        @metadata = metadata
      end

      def set_file key, file_data
        raise "Multiple specification of file '#{key}'" unless @files[key].nil?
        @files[key] = file_data
      end

    end
  end
end