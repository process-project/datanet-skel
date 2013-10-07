module Datanet
  module Skel
    module Search
      NUMBER_OPERATORS = [:<, :<=, :>, :>=, :!=]

      def self.decode(params, collection)
        params.inject({}) do |hsh, entity|
          k, v = entity.first, entity.last
          attr_type = collection.attr_type k
          if v.nil? or attr_type.nil?
            hash[k] = v
          else
            if attr_type == :number
              NUMBER_OPERATORS.each do |operator|
                hsh[k] = {value: v[operator.length, v.length].to_f, operator: operator} if v.start_with? operator.to_s
              end
              hsh[k] = v.to_f if hsh[k].nil?
            elsif attr_type == :string
              hsh[k] = {value: v[1, v.length-2], operator: :regexp} if v =~ /\A\/.*\/\z/
            elsif attr_type == :array
              hsh[k] = {value: v.split(','), operator: :contains}
            end

            hsh[k] = v if hsh[k].nil?
          end
          hsh
        end
      end
    end
  end
end