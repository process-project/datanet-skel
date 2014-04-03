module Datanet
  module Skel
    class ConfigurationApi < Grape::API
      version 'v1', :using => :header, :vendor => 'datanet'
      format :json

      helpers do
        def authenticate!
          unauthorized! unless API.auth.admin? private_token
        end

        def private_token
          params[:private_token] || env["HTTP_PRIVATE_TOKEN"]
        end
      end

      before do
        render_api_error!('Config module not registered', 404) unless API.auth
        authenticate!
      end

      resource :_configuration do
        get do
          API.auth.configuration
        end

        put do
          attrs = attributes_for_keys [:repository_type, :owners, :cors_origins]
          API.auth.repository_type = attrs[:repository_type].to_sym if attrs[:repository_type]
          API.auth.owners = attrs[:owners] if attrs[:owners]
          API.auth.cors_origins = attrs[:cors_origins] if attrs[:cors_origins]
          API.auth.configuration
        end
      end
    end
  end
end