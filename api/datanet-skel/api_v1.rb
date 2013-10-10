require 'datanet-skel/exceptions'
require 'datanet-skel/multipart'
require 'datanet-skel/file_transmition'
require 'datanet-skel/sftp_connection'

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
        Rack::Response.new([e.message], 422)
      end

      rescue_from Datanet::Skel::FileStorageException do |e|
        Rack::Response.new([ "File storage error: #{e.message.nil? ? e.class : e.message}"], 422)
      end

      http_basic do |user,password|
        API.auth ? API.auth.authenticate(user, password) : true
      end

      helpers do

        def storage_host
          API.storage_host
        end

        def mapper
          API.mapper
        end

        def doc!
          if form_data
            JSON.parse(form_data.metadata)
          else
            JSON.parse(env['rack.input'].string)
          end
        end

        def form_data
          params[:datanet_form_multipart] ||= Datanet::Skel::Multipart.new(env["rack.request.form_hash"]) if
              @request.form_data? && env["rack.request.form_hash"]
        end

        def new_sftp_connection
          raise Datanet::Skel::FileStorageException.new("File storage authentication is disabled for this repository.") unless API.auth_storage
          user, password = credentials
          Datanet::Skel::SftpConnection.new(storage_host, user, password)
        end

        def credentials
          Rack::Auth::Basic::Request.new(env).credentials
        end

        def file_transmition
          Datanet::Skel::FileTransmition.new(new_sftp_connection, form_data.files) if form_data && form_data.files
        end

        def collection
          mapper.collection(params[:collection_name])
        end

        def entity!
            collection.get id
        end

        def file!
          collection.get_file id, new_sftp_connection if file_request
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
      resource '/' do

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
          if request.params.size > 0 then
            collection.search(Datanet::Skel::Search.decode(request.params, collection))
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
          collection.add(doc!, file_transmition)
        end

        desc "Get entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        get ":collection_name/:id" do
          logger.debug "Getting #{params[:collection_name]}/#{params[:_id]}"
          if file_request
            payload, file_name = file!
            header "Content-Type", "application/octet-stream"
            header "Content-Disposition", "attachment;filename=\"#{file_name}\""
            payload
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
           attr_value ? attr_value : attribute_not_found()
        end

        desc "Delete entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        delete ":collection_name/:id" do
          collection.remove id
          nil
        end

        desc "Update entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        post ":collection_name/:id" do
          collection.update id, doc!
          nil
        end

        desc "Replace entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        put ":collection_name/:id" do
          collection.replace id, doc!
          nil
        end
      end
    end
  end
end