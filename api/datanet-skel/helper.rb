module Datanet
  module Skel
    module APIHelpers
      def unauthorized!
        render_api_error!('401 Unauthorized', 401)
      end

      def attributes_for_keys(keys)
        attrs = {}
        keys.each do |key|
          attrs[key] = params[key] if !blank?(params[key])
        end
        attrs
      end


      def blank?(str)
        str.respond_to?(:empty?) ? str.empty? : !str
      end

      def render_api_error!(message, status)
        error!({'message' => message}, status)
      end
    end
  end
end