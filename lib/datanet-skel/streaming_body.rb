module Datanet
  module Skel
    class StreamingBody
      def initialize(collection, id, user_proxy)
        @collection, @id, @user_proxy = collection, id, user_proxy
      end

      def each
        @collection.get_file(@id, @user_proxy) do |data|
          yield data
        end
      end
    end
  end
end