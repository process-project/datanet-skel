require 'spec_helper'

describe Datanet::Skel::API_v1 do
	include Rack::Test::Methods

	def app
		Datanet::Skel::API
	end

	def headers(options={})
		{'HTTP_ACCEPT' => "application/vnd.datanet-v1+json"}.merge(options)		
	end

	before(:each) do
		@user_collection = mock(Datanet::Skel::CollectionMock)
		@mapper = mock(Datanet::Skel::MapperMock)		
		@mapper.stub(:collection).with('user')
			.and_return(@user_collection)

		Datanet::Skel::API.mapper = @mapper		
	end	

	describe 'GET /list' do
		it 'lists collections names' do		
			collections = ['a', 'b', 'c']
			@mapper.stub(:collections).and_return(collections)
			
			get 'list', nil, headers
			last_response.status.should == be_ok		
			JSON.parse(last_response.body).should == collections
		end

		it 'lists empty collections names' do
			@mapper.stub(:collections).and_return(nil)
			
			get 'list', nil, headers
			last_response.status.should == be_ok		
			JSON.parse(last_response.body).should == []		
		end
	end

	describe 'GET /entity/:collection_name' do
		it 'gets non existing collection' do
			@mapper.stub(:collection).with('non_existing')
				.and_raise(Datanet::Skel::CollectionNotFoundException.new)

			get 'entity/non_existing', nil, headers
			last_response.status.should == 404
		end

		it 'gets user collection entities ids' do		
			ids = ['1', '2', '3']
			@user_collection.stub(:ids).and_return(ids)		
					
			get 'entity/user', nil, headers
			last_response.status.should == 200
			JSON.parse(last_response.body).should == ids		
		end

		it 'gets empty user collection entities ids' do
			@user_collection.stub(:ids).and_return(nil)		
					
			get 'entity/user', nil, headers
			last_response.status.should == 200
			JSON.parse(last_response.body).should == []
		end
	end

	describe 'POST /entity/:collection_name' do
		it 'adds valid entity into user collection' do
			new_user = {'first_name' => 'marek', 'age' => 31}
			@user_collection.stub(:add).with(new_user).and_return(user_id)

			post 'entity/user', new_user.to_json, headers
			last_response.status.should == 201
			last_response.body.should == 
			user_id
		end

		it 'adds invalid entity into user collection' do
			new_user = {'first_name' => 'marek'}
			@user_collection.stub(:add).with(new_user)
				.and_raise(Datanet::Skel::ValidationError.new)

			post 'entity/user', new_user.to_json, headers
			last_response.status.should == 422
			# TODO check validation error message
		end
	end

	describe 'GET /entity/:collection_name/:id' do
		it 'gets existing user entity' do
			user = {'first_name' => 'marek', 'age' => 31}
			@user_collection.stub(:get).with(user_id).and_return(user)

			get "entity/user/#{user_id}", nil, headers
			last_response.status.should == be_ok
			JSON.parse(last_response.body).should == user
		end

		it 'gets non existing user entity' do			
			@user_collection.stub(:get).with(user_id)
				.and_raise(entity_not_found_error(user_id))

			get "entity/user/#{user_id}", nil, headers
			entity_not_found?(user_id)
		end
	end

	describe 'DELETE /entity/:collection_name/:id' do
		it 'deletes existing user entity' do
			@user_collection.stub(:remove).with(user_id)

			delete "entity/user/#{user_id}", nil, headers
			last_response.status.should == be_ok
		end

		it 'deletes non existing user entity' do			
			@user_collection.stub(:remove).with(user_id)
				.and_raise(entity_not_found_error(user_id))

			delete "entity/user/#{user_id}", nil, headers
			entity_not_found?(user_id)
		end
	end

	describe 'POST /entity/:collection_name/:id' do
		it 'updates existing user entity' do
			update = {'first_name' => 'Marek'}
			@user_collection.stub(:update).with(user_id, update)

			post "entity/user/#{user_id}", update.to_json, headers
			last_response.status.should == be_ok
		end

		it 'updates non existing user entity' do
			doc = {'not' => 'important'}
			@user_collection.stub(:update).with(user_id, doc)
				.and_raise(entity_not_found_error(user_id))

			post "entity/user/#{user_id}", doc.to_json, headers
			entity_not_found?(user_id)
		end

		it 'updates existing user entity with not correct values' do
			mandatory_parameter_set_to_nil = {'first_name' => nil}
			@user_collection.stub(:update).with(user_id, mandatory_parameter_set_to_nil)
				.and_raise(Datanet::Skel::ValidationError.new)			

			post "entity/user/#{user_id}", mandatory_parameter_set_to_nil.to_json, headers
			last_response.status.should == 422
			# TODO check validation error message
		end
	end

	describe 'PUT /entity/:collection_name/:id' do
		it 'overwites existing user entity' do
			updated_user = {'first_name' => 'marek', 'age' => 31}
			@user_collection.stub(:replace).with(user_id, updated_user)
				.and_raise(entity_not_found_error(user_id))

			put "entity/user/#{user_id}", updated_user.to_json, headers
			last_response.status.should == be_ok
		end

		it 'overwrites non existing user entity' do
			doc = {'not' => 'important'}
			@user_collection.stub(:replace).with(user_id, doc)
				.and_raise(entity_not_found_error(user_id))

			put "entity/user/#{user_id}", doc.to_json, headers
			entity_not_found?(user_id)
		end

		it 'overwrites existing user entity with not correct values' do
			update_without_mandatory_param = {'age' => 31}
			@user_collection.stub(:replace).with(user_id, update_without_mandatory_param)
				.and_raise(Datanet::Skel::ValidationError.new)			

			put "entity/user/#{user_id}", update_without_mandatory_param.to_json, headers
			last_response.status.should == 422
			# TODO check validation error message
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