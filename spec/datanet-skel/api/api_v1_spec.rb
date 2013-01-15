require 'spec_helper'
require 'base64'

describe Datanet::Skel::API_v1 do
	include Rack::Test::Methods

	def app
		Datanet::Skel::API
	end

	def headers(options={})
		{'HTTP_ACCEPT' => "application/vnd.datanet-v1+json",
     'HTTP_AUTHORIZATION' => "Basic " + Base64.encode64("test_username:test_password")}.merge(options)
	end

	before(:each) do
		@user_collection = mock(Datanet::Skel::CollectionMock)
		@mapper = mock(Datanet::Skel::MapperMock)
		@mapper.stub(:collection).with('user')
			.and_return(@user_collection)

		Datanet::Skel::API.mapper = @mapper
	end

	describe 'GET /' do
		it 'lists collections names' do
			collections = ['a', 'b', 'c']
			@mapper.should_receive(:collections).and_return(collections)

			get '/', nil, headers
			last_response.status.should == be_ok
			JSON.parse(last_response.body).should == collections
		end

		it 'lists empty collections names' do
			@mapper.should_receive(:collections).and_return(nil)

			get '/', nil, headers
			last_response.status.should == be_ok
			JSON.parse(last_response.body).should == []
		end
	end

	describe 'GET :collection_name' do
		it 'gets non existing collection' do
			@mapper.should_receive(:collection).with('non_existing')
				.and_raise(Datanet::Skel::CollectionNotFoundException.new)

			get 'non_existing', nil, headers
			last_response.status.should == 404
		end

		it 'gets user collection entities ids' do
			ids = ['1', '2', '3']
			@user_collection.should_receive(:ids).and_return(ids)

			get 'user', nil, headers
			last_response.status.should == 200
			JSON.parse(last_response.body).should == ids
		end

		it 'gets empty user collection entities ids' do
			@user_collection.should_receive(:ids).and_return(nil)

			get 'user', nil, headers
			last_response.status.should == 200
			JSON.parse(last_response.body).should == []
		end
	end

	describe "GET /:collection_name?search=value" do
		it 'gets entities ids using single query element' do
			ids = ['1', '2']
			@user_collection.should_receive(:search).with({"name" => "marek"}).and_return(ids)

			get 'user?name=marek', nil, headers
			last_response.status.should == 200
			JSON.parse(last_response.body).should == ids
		end

		it 'gets entities ids using complex (AND) query' do
			ids = ['1', '3']
			@user_collection.should_receive(:search)
				.with({"name" => "marek", "age" => "31"}).and_return(ids)

			get 'user?name=marek&age=31', nil, headers
			last_response.status.should == 200
			JSON.parse(last_response.body).should == ids
		end
	end

	describe 'POST /:collection_name' do
		it 'adds valid entity into user collection' do
			new_user = {'first_name' => 'marek', 'age' => 31}
			@user_collection.should_receive(:add).with(new_user).and_return(user_id)

			post 'user', new_user.to_json, headers
			last_response.status.should == 201
			last_response.body.should == user_id
		end

		it 'adds invalid entity into user collection' do
			new_user = {'first_name' => 'marek'}
			@user_collection.should_receive(:add).with(new_user)
				.and_raise(Datanet::Skel::ValidationError.new)

			post 'user', new_user.to_json, headers
			last_response.status.should == 422
			# TODO check validation error message
		end
	end

	describe 'GET /:collection_name/:id' do
		it 'gets existing user entity' do
			user = {'first_name' => 'marek', 'age' => 31}
			@user_collection.should_receive(:get).with(user_id).and_return(user)

			get "user/#{user_id}", nil, headers
			last_response.status.should == be_ok
			JSON.parse(last_response.body).should == user
		end

		it 'gets non existing user entity' do
			@user_collection.should_receive(:get).with(user_id)
				.and_raise(entity_not_found_error(user_id))

			get "user/#{user_id}", nil, headers
			entity_not_found?(user_id)
		end
	end

	describe 'DELETE /:collection_name/:id' do
		it 'deletes existing user entity' do
			@user_collection.should_receive(:remove).with(user_id)

			delete "user/#{user_id}", nil, headers
			last_response.status.should == be_ok
		end

		it 'deletes non existing user entity' do
			@user_collection.should_receive(:remove).with(user_id)
				.and_raise(entity_not_found_error(user_id))

			delete "user/#{user_id}", nil, headers
			entity_not_found?(user_id)
		end
	end

	describe 'POST /:collection_name/:id' do
		it 'updates existing user entity' do
			update = {'first_name' => 'Marek'}
			@user_collection.should_receive(:update).with(user_id, update)

			post "user/#{user_id}", update.to_json, headers
			last_response.status.should == be_ok
		end

		it 'updates non existing user entity' do
			doc = {'not' => 'important'}
			@user_collection.should_receive(:update).with(user_id, doc)
				.and_raise(entity_not_found_error(user_id))

			post "user/#{user_id}", doc.to_json, headers
			entity_not_found?(user_id)
		end

		it 'updates existing user entity with not correct values' do
			mandatory_parameter_set_to_nil = {'first_name' => nil}
			@user_collection.should_receive(:update).with(user_id, mandatory_parameter_set_to_nil)
				.and_raise(Datanet::Skel::ValidationError.new)

			post "user/#{user_id}", mandatory_parameter_set_to_nil.to_json, headers
			last_response.status.should == 422
			# TODO check validation error message
		end
	end

	describe 'PUT /:collection_name/:id' do
		it 'overwites existing user entity' do
			updated_user = {'first_name' => 'marek', 'age' => 31}
			@user_collection.should_receive(:replace).with(user_id, updated_user)
				.and_raise(entity_not_found_error(user_id))

			put "user/#{user_id}", updated_user.to_json, headers
			last_response.status.should == be_ok
		end

		it 'overwrites non existing user entity' do
			doc = {'not' => 'important'}
			@user_collection.should_receive(:replace).with(user_id, doc)
				.and_raise(entity_not_found_error(user_id))

			put "user/#{user_id}", doc.to_json, headers
			entity_not_found?(user_id)
		end

		it 'overwrites existing user entity with not correct values' do
			update_without_mandatory_param = {'age' => 31}
			@user_collection.should_receive(:replace).with(user_id, update_without_mandatory_param)
				.and_raise(Datanet::Skel::ValidationError.new)

			put "user/#{user_id}", update_without_mandatory_param.to_json, headers
			last_response.status.should == 422
			# TODO check validation error message
		end
	end

	describe 'GET /:collection_name/schema' do
		it 'returns schema json' do
			schema = {
				"type" => "object",
				"properties" => {
					"name" => {"type" => "string", "required" => true},
					"age" => {"type" => "integer"}
				}
			}
			@user_collection.should_receive(:schema).and_return(schema)

			get 'user/schema', nil, headers
			last_response.status.should == be_ok
			JSON.parse(last_response.body).should == schema
		end
		it 'return 404 when schema is not found' do
			@mapper.should_receive(:collection).with('non_existing')
				.and_raise(Datanet::Skel::CollectionNotFoundException.new)

			get 'non_existing/schema', nil, headers
			last_response.status.should == 404
		end
	end

	def entity_not_found?(id)
		last_response.status.should == 404
		JSON.parse(last_response.body).should ==
			{'message' => entity_not_found_message(id)}
	end

	def entity_not_found_error(id)
		Datanet::Skel::EntityNotFoundException.new(entity_not_found_message(id))
	end

	def entity_not_found_message(id)
		"Entity with #{id} not found"
	end

	def user_id
		@user_id ||= '1234'
	end
end