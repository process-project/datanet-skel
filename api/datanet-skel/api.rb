require 'grape'

module Datanet
  module Skel
    class API < Grape::API
      format :json

      mount ::Datanet::Skel::API_v1

      class << self
          attr_accessor :mapper
        end
    end
  end
end