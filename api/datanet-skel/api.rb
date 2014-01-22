require 'grape'
require 'grape/middleware/formatter'

class Grape::Middleware::Formatter

  alias_method :old_after, :after

  def after
    status, headers, bodies = *@app_response
    if headers["Content-Type"] == 'application/octet-stream'
      [status, headers, bodies.first]
    else
      old_after
    end
  end
end

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