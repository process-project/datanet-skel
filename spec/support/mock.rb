module Datanet
  module Skel
    class MapperMock
      def collections
      end

      def collection(entity_type)
      end
    end

    class CollectionMock
      def initialize obj

      end

      def ids
      end

      def add(json_doc, references_map)
      end

      def get(id)
      end

      def remove(id)
      end

      def update(id, json_doc, references_map)
      end

      def replace(id, json_doc, references_map)
      end
    end
  end
end