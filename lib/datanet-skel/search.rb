module Datanet
  module Skel
    module Search
      NUMBER_OPERATORS = [:<, :<=, :>, :>=, :!=]

      def self.decode(params, collection)
        params.inject({}) do |hsh, entity|
          k, v = entity.first, entity.last
          attr_type = collection.attr_type k
          if v.nil? or attr_type.nil?
            hsh[k] = v
          else
            v = [v] unless v.instance_of? Array
            values = []
            v.reject(&:nil?).each do |element|
              values << case attr_type
                          when :number  then number_operator(element)
                          when :integer then number_operator(element)
                          when :string  then string_operator(element)
                          when :array   then to_array(element)
                          when :boolean then to_boolean(element)
                          else element
                        end
            end
            hsh[k] = case values.size
                          when 0 then v
                          when 1 then values[0]
                          else values
                        end
          end
          hsh
        end
      end

      private

      def self.to_array(element)
        {value: element.split(','), operator: :contains}
      end

      def self.number_operator(element)
        result = nil
        NUMBER_OPERATORS.each do |operator|
          result = {value: element[operator.length, element.length].to_f, operator: operator} if element.start_with? operator.to_s
        end
        result || element.to_f
      end

      def self.string_operator(element)
        element =~ /\A\/.*\/\z/ ? {value: element[1, element.length-2], operator: :regexp} : element
      end

      def self.to_boolean(s)
        !!(s =~ /^(true|yes|1)$/i)
      end
    end
  end
end