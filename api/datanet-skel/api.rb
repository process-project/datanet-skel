require 'grape'

module Datanet
  module Skel
    class API < Grape::API
      #format :json

      helpers ::Datanet::Skel::APIHelpers

      mount ::Datanet::Skel::ConfigurationApi
      mount ::Datanet::Skel::API_v1

      class << self
        attr_accessor :mapper, :storage_host, :auth, :auth_storage
      end
    end
  end
end