require 'json-schema'
require 'delegate'
require 'datanet-skel/transaction'
require 'datanet-skel/file_storage'
require 'datanet-skel/exceptions'

module Datanet
  module Skel
    class MapperDecorator < SimpleDelegator
      attr_accessor :model_location

      def initialize(obj)
        super(obj)
      end

      def collections
        raise Datanet::Skel::WrongModelLocationError, 'Wrong models directory location' unless
          File.directory?(model_location)

        collections = []
        Dir[File.join(model_location, "*.json")].each { |file|
          collections << File.basename(file, '.json')
        }

        raise Datanet::Skel::WrongModelLocationError, 'No models in selected models directory' if
          collections.size == 0

        collections.sort!
      end

      def file_storage
        @file_storage ||= Datanet::Skel::FileStorage.new
      end

      def collection(entity_type)
        path = entity_path!(entity_type)
        if entity_type == 'file'
          FileEntityDecorator.new(super, path, file_storage, self)
        else
          EntityDecorator.new(super, path, file_storage, self)
        end
      end

    private

      def entity_path!(entity_type)
        path = entity_path entity_type
        raise CollectionNotFoundException.new "Entity #{entity_type} not found" unless
          File.exists? path
        path
      end

      def entity_path(entity_type)
        File.join(model_location, "#{entity_type}.json")
      end
    end

    class EntityDecorator < SimpleDelegator

      def initialize(obj, model_path, file_storage, decorated_mapper)
        @model_path = model_path
        @file_storage = file_storage
        @decorated_mapper = decorated_mapper
        @inspector = Datanet::Skel::RelationInspector.new(model_path)
        super(obj)
      end

      def add(json_doc, file_transmission = nil)

        Datanet::Skel::Transaction.new.in_transaction do |transaction|
          unless file_transmission.nil? ||  file_transmission.files.nil?
            file_transmission.files.each do |attr, file|

              unless json_doc["#{attr}_id"].nil?
                raise Datanet::Skel::ValidationError.new "File upload conflicts with metadata attribute \'#{attr}\'"
              end

              file_upload = Class.new(Datanet::Skel::AtomicAction) do
                def initialize(transaction, file_storage, sftp_connection, payload_stream)
                  @file_storage = file_storage
                  @sftp_connection = sftp_connection
                  @payload_stream = payload_stream
                  @path = nil
                  super(transaction)
                end
                def action
                  @path = @file_storage.generate_path @sftp_connection
                  @file_storage.store_payload(@sftp_connection, @payload_stream.read, @path) # TODO pass payload as a stream not a string
                rescue Exception => e
                  raise Datanet::Skel::FileStorageException.new(e)
                end
                def rollback
                  @file_storage.delete_file(@sftp_connection, @path) if @path
                end
              end.new(transaction, @file_storage, file_transmission.sftp_connection, file[:payload_stream])

              path = file_upload.run_action

              file_to_db = Class.new(Datanet::Skel::AtomicAction) do
                def initialize(transaction, file_name, path, decorated_mapper)
                  @file_name = file_name
                  @path = path
                  @decorated_mapper = decorated_mapper
                  @file_id = nil
                  super(transaction)
                end
                def action
                  file_json = { 'file_name' => @file_name, 'file_path' => @path }
                  @file_id = @decorated_mapper.collection('file').add(file_json)
                end
                def rollback
                  @decorated_mapper.collection('file').remove(@file_id) unless @file_id.nil?
                end
              end.new(transaction, file[:filename], path, @decorated_mapper)

              json_doc["#{attr}_id"] = file_to_db.run_action
            end
          end

          valid! json_doc
          super(json_doc, @inspector.relations)
        end

      end

      def replace(id, json_doc)
        valid! json_doc
        super(id, json_doc, @inspector.relations)
      end

      def update(id, json_doc)
        old_json_doc = get id
        merged_json = old_json_doc.merge(json_doc)
        valid! merged_json
        super(id, json_doc, @inspector.relations)
      end

      def schema
        JSON.parse(File.read(@model_path))
      end

    private

      def valid!(json_doc)
        begin
          JSON::Validator.validate!(@model_path, json_doc)
        rescue JSON::Schema::ValidationError
          raise Datanet::Skel::ValidationError.new $!.message[0, $!.message.index(' in schema')]
        rescue
          raise Datanet::Skel::ValidationError.new 'Wrong json format'
        end
      end

    end

    class FileEntityDecorator < EntityDecorator
      def get_file id, connection
        file_entity = get(id)
        begin
          payload = @file_storage.get_file(connection, file_entity['file_path'])
        rescue Exception => e
          raise Datanet::Skel::FileStorageException.new(e)
        end
        [ payload , file_entity['file_name'] ]
      end
    end

  end
end
