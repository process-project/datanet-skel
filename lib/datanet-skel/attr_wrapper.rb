module Datanet
  module Skel
    class AttrWrapper
      def initialize(val)
        @val = val
      end

      def to_json
        @val
      end
    end
  end
end