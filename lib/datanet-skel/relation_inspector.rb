module Datanet
  module Skel
    class RelationInspector

      attr_reader :relations

      def initialize(model_path)
        @model = JSON.parse(IO.read(model_path))
        find_relations
      end

    private

      def find_relations
        @relations = {}

        @model['links'].each{|link|
          check_and_add_relation(link) if link['targetSchema']
        } if @model['links']
      end

      def check_and_add_relation(link)
        @model['properties'].each_key {|k|
          @relations[k] = link['targetSchema'] if
            link['href'].include?("{#{k}}")
        }
      end
    end
  end
end