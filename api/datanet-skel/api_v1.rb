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

      rescue_from Datanet::Skel::ValidationError do |e|
        Rack::Response.new([e.message], 422)
      end

      rescue_from Datanet::Skel::FileStorageException do |e|
        Rack::Response.new([e.message], 422)
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
          if @request.form_data?
            JSON.parse(form_data.metadata)
          else
            JSON.parse(env['rack.input'].string)
          end
        end

        def new_sftp_connection
          user, password = Rack::Auth::Basic::Request.new(env).credentials
          Datanet::Skel::SftpConnection.new(storage_host, user, password)
        end

        def file_transmition
          if @request.form_data? && form_data.files
            Datanet::Skel::FileTransmition.new(new_sftp_connection, form_data.files)
          else
            nil
          end
        end

        def collection
          mapper.collection(params[:collection_name])
        end

        def entity!
          collection.get id
        end

        def id
          params[:id]
        end

        def form_data
          params[:multipart_form_data] ||= Datanet::Skel::Multipart.new(env["rack.request.form_hash"])
        end

        def logger
          API.logger
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

        desc "Get all ids of the elements stored in this Entity"
        params do
          requires :collection_name, :desc => 'Collection name'
        end
        get ":collection_name" do
          if request.params.size > 0 then
            collection.search(request.params)
          else
            collection.ids or []
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

        desc "Get entity schema"
        params do
          requires :collection_name, :desc => 'Collection name'
        end
        get ':collection_name/schema' do
          collection.schema
        end

        desc "Get entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        get ":collection_name/:id" do
           logger.debug "Getting #{params[:collection_name]}/#{params[:_id]}"
           entity!
        end

        desc "Delete entity with given id"
        params do
          requires :collection_name, :desc => 'Collection name'
          requires :id, :desc => "Entity id"
        end
        delete ":collection_name/:id" do
          collection. remove id
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