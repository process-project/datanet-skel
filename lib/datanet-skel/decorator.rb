require 'json-schema'
require 'delegate'
require 'datanet-skel/transaction'
require 'datanet-skel/file_storage'
require 'datanet-skel/exceptions'
require 'grid-proxy'

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
        collection = collections - ['file']

        raise Datanet::Skel::WrongModelLocationError, 'No models in selected models directory' if collections.size == 0

        collection.sort!
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
            proxy = GP::Proxy.new file_transmission.proxy_payload

            file_transmission.files.each do |attr_name, file|

              unless json_doc["#{attr_name}"].nil?
                raise Datanet::Skel::ValidationError, "File upload conflicts with metadata attribute \'#{attr_name}\'"
              end

              file_upload = Class.new(Datanet::Skel::AtomicAction) do
                def initialize(transaction, file_storage, proxy, payload_stream)
                  @file_storage = file_storage
                  @proxy = proxy
                  @payload_stream = payload_stream
                  @path = nil
                  super(transaction)
                end
                def action
                  @path = @file_storage.generate_path @proxy
                  @file_storage.store_payload(@proxy, @payload_stream, @path) # TODO pass payload as a stream not a string
                rescue Exception => e
                  raise Datanet::Skel::FileStorageException.new(e)
                end
                def rollback
                  @file_storage.delete_file(@proxy, @path) if @path
                end
              end.new(transaction, @file_storage, proxy, file[:payload_stream])

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
              end.new(transaction, sanitize_filename(file[:filename]), path, @decorated_mapper)

              json_doc["#{attr_name}"] = file_to_db.run_action
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

      def remove(id, proxy)
        entity = get(id)
        remove_dependencies(entity, proxy)

        super
      end

      def schema
        JSON.parse(File.read(@model_path))
      end

      ATTR_TYPES_MAP = {
        'string' => :string,
        'integer' => :integer,
        'number' => :number,
        'array' => :array,
        'boolean' => :boolean
      }

      def attr_type(attr_name)
        raw_type = raw_attr_type attr_name
        raw_type ? ATTR_TYPES_MAP[raw_type] : nil
      end

    protected

      def remove_dependencies(entity, proxy)
        @inspector.relations.each do |k, v|
          remove_file([entity[k]].flatten, proxy) if v == 'file'
        end
      end

    private

      def remove_file(ids, proxy)
        ids.each do |id|
          @decorated_mapper
            .collection('file')
              .remove(id, proxy) if id
        end
      end

      def sanitize_filename(filename)
        filename.gsub("\n", '_')
      end

      def raw_attr_type(attr_name)
        schema['properties'][attr_name]['type'] if schema['properties'][attr_name]
      end

      def valid!(json_doc)
        begin
          errors = JSON::Validator.fully_validate(@model_path, json_doc)
          raise Datanet::Skel::ValidationError, errors.collect { |msg| msg[0, msg.index(' in schema')] } if errors.length > 0
        rescue
          raise Datanet::Skel::ValidationError, ['Wrong json format']
        end
      end

    end

    class FileEntityDecorator < EntityDecorator
      def get_filename(id)
        get(id)['file_name']
      end

      def get_file(id, proxy_payload, &block)
        file_entity = get(id)
        proxy = GP::Proxy.new proxy_payload
        @file_storage.get_file(proxy, file_entity['file_path'], &block)
      end

      protected

        def remove_dependencies(entity, proxy)
          @file_storage.delete_file(proxy, entity['file_path'])
        end
    end
  end
end
