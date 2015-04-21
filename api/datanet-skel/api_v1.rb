require 'datanet-skel/exceptions'
require 'datanet-skel/multipart'
require 'datanet-skel/file_transmition'
require 'base64'
require 'rack/stream'
require 'rack/utils'
require 'ruby-gridftp'

module Datanet
  module Skel
    class API_v1 < Grape::API

      version 'v1', :using => :header, :vendor => 'datanet'

      format :json
      default_format :json
      content_type :json, "application/json"
      content_type :multipart, "multipart/form-data"

      rescue_from Datanet::Skel::CollectionNotFoundException do |e|
        rack_response({:message => e.message}.to_json, 404)
      end

      rescue_from Datanet::Skel::EntityNotFoundException do |e|
        rack_response({:message => e.message}.to_json, 404)
      end

      rescue_from Datanet::Skel::EntityAttributeNotFoundException do |e|
        rack_response({:message => e.message}.to_json, 404)
      end

      rescue_from Datanet::Skel::ValidationError do |e|
        rack_response({:message => e.message}.to_json, 422)
      end

      rescue_from Datanet::Skel::FileStorageException do |e|
        rack_response({:message => "File storage error: #{e.message.nil? ? e.class : e.message}"}.to_json, 422)
      end

      rescue_from GFTP::GlobusError do |e|
        rack_response({:message => "Grid FTP error: #{e.message.nil? ? e.class : e.message}"}.to_json, 403)
      end

      rescue_from Datanet::Skel::Unauthenticated do |e|
        rack_response({:message => e.message}.to_json, 401)
      end

      rescue_from Datanet::Skel::Unauthorized do |e|
        rack_response({:message => e.message}.to_json, 403)
      end

      rescue_from Datanet::Skel::PermissionDenied do |e|
        rack_response({:message => e.message}.to_json, 403)
      end

      rescue_from Exception do |e|
        rack_response({:message => 'Internal application error, please contact Datanet administrator'}.to_json, 500)
      end

      before do
        if API.auth
          API.auth.authenticate!(user_proxy)
          API.auth.authorize!(user_proxy)
        end
      end

      helpers do
        include Rack::Stream::DSL

        def valid_credentials?
          API.auth ? API.auth.authenticate(user_proxy) : true
        end

        def query_grid_proxy
          Rack::Utils.parse_nested_query(env['QUERY_STRING'])['grid_proxy']
        end

        def user_proxy
          (Base64.decode64(decoded_user_proxy) if decoded_user_proxy) || query_grid_proxy
        end

        def decoded_user_proxy
          @decoded_grid_proxy ||= headers['Grid-Proxy'] || env['GRID_PROXY']
        end

        def mapper
          API.mapper
        end

        def doc!
          if form_data
            fix_types JSON.parse(form_data.metadata)
          else
            JSON.parse(env['rack.input'].gets || env['rack.input'].string)
          end
        end

        def fix_types(json)
          json.inject({}) do |hsh, entity|
            k, v = entity.first, entity.last
            attr_type = collection.attr_type k
            begin
              hsh[k] = case attr_type
                      when :integer then v.to_i
                      when :number then v.to_f
                      when :array then JSON.parse(v)
                      else
                        v
                      end
            rescue
              hsh[k] = v
            end
            hsh
          end
        end

        def form_data
          params[:datanet_form_multipart] ||= Datanet::Skel::Multipart.new(env["rack.request.form_hash"]) if @request.form_data? && env["rack.request.form_hash"]
        end

        def file_transmition
          Datanet::Skel::FileTransmition.new(user_proxy, form_data.files) if form_data && form_data.files
        end

        def username
          API.auth.username(user_proxy)
        end

        def collection
          mapper.collection(params[:collection_name], username)
        end

        def entity!
            collection.get id
        end

        def file!
          collection.get_file id, user_proxy if file_request
        end

        def id
          params[:id]
        end

        def file_request
          params[:collection_name] == 'file'
        end

        def logger
          API.logger
        end

        def attribute_not_found
          raise EntityAttributeNotFoundException.new "Attribute #{params[:attr_name]} not found in #{id} #{params[:collection_name]} entity"
        end

        def halt_on_empty!(obj, status, message)
          if obj.nil?
            halt status, message
          else
            obj
          end
        end
      end

      desc "List registered collections names"
      get do
        mapper.collections or []
      end

      desc "Model entities."
      resource do

        desc "Get entity schema"
        params do
          requires :collection_with_schema, :desc => 'Collection name with .schema'
        end
        get ':collection_with_schema', requirements: { collection_with_schema: /[\w-]*\.schema/} do
          collection_with_schema = params[:collection_with_schema]
          params[:collection_name] = collection_with_schema[0, collection_with_schema.length - 7]
          collection.schema
        end

        desc "Get all ids of the elements stored in this Entity"
        params do
          requires :collection_name, :desc => 'Collection name'
        end
        get ":collection_name" do
          query_hash = env["rack.request.query_hash"].dup
          query_hash.delete('grid_proxy')
          if query_hash.size > 0 then
            collection.search(Datanet::Skel::Search.decode(query_hash, collection))
          else
            collection.index or []
          end
        end

        desc "Add new entity"
        params do
          requires :collection_name, :desc => 'Collection name'
        end
        post ":collection_name" do
          logger.debug "Adding new entity into '#{params[:collection_name]}' collection"
          {id: collection.add(doc!, file_transmition) }
        end

        desc "Get entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        get ":collection_name/:id" do
          logger.debug "Getting #{params[:collection_name]}/#{params[:_id]}"
          if file_request
            logger.debug "Getting file"
            status 200
            header "Content-Type", "application/octet-stream"
            header "Content-Disposition", "attachment;filename=\"#{collection.get_filename(id)}\""
            Datanet::Skel::StreamingBody.new(collection, id, user_proxy)
          else
            entity!
          end
        end

        desc "Get entity attribute with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
          requires :attr_name, :desc => "Attribute name"
        end
        get ":collection_name/:id/:attr_name" do
           logger.debug "Getting #{params[:collection_name]}/#{params[:_id]}//#{params[:attr_name]}"
           attr_value = entity![params[:attr_name]]
           attr_value ? AttrWrapper.new(attr_value) : attribute_not_found()
        end

        desc "Delete entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        delete ":collection_name/:id" do
          collection.remove(id, user_proxy)
          {}
        end

        desc "Update entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        post ":collection_name/:id" do
          collection.update id, doc!
          {}
        end

        desc "Replace entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        put ":collection_name/:id" do
          collection.replace id, doc!
          {}
        end
      end
    end
  end
end
