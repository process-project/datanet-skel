require 'json-sche#To change this template use File | Settings | File Templates.
    true.should == falsema'
require 'delegate'

module Datanet
  module Skel
    class MapperDecorator < SimpleDelegator
      attr_accessor :model_location

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

      def collection(entity_type)
        path = entity_path!(entity_type)
        EntityDecorator.new super, path
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
      def initialize(obj, model_path)
        @model_path = model_path
        @inspector = Datanet::Skel::RelationInspector.new(model_path)

        super(obj)
      end

      def add(json_doc)
        valid! json_doc
        super(json_doc, @inspector.relations)
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
        rescue
          raise Datanet::Skel::ValidationError.new 'Wrong json format'
        end
      end
    end
  end
end