require 'spec_helper'
require 'base64'
require 'datanet-skel/file_transmition'
require 'open-uri'

describe Datanet::Skel::API_v1 do
	include Rack::Test::Methods
  include ApiHelpers

	def app
    Datanet::Skel::API.auth_storage ||= double

		Datanet::Skel::API
  end

  def grid_proxy
    Base64.encode64(proxy_payload)
  end

  def proxy_payload
    'grid_proxy_payload_base64_encoded_without_new_lines'
  end

  def headers(options={})
    {'HTTP_ACCEPT' => "application/vnd.datanet-v1+json",
     'GRID_PROXY' => grid_proxy,
     'CONTENT_TYPE' => "application/json"}.merge(options)
  end

  def headers_multipart(options={})
    {'HTTP_ACCEPT' => "application/vnd.datanet-v1+json",
     'GRID_PROXY' => grid_proxy,
     'CONTENT_TYPE' => "multipart/form-data; boundary=AaB03x",
    }.merge(options)
  end

  def multipart_stream(name)
    file = File.join(File.dirname(__FILE__), "../multipart", name.to_s)
    data = File.open(file, 'rb') { |io| io.read }
    StringIO.new(data)
  end

  let(:file_collection) { double('file collection') }

  before(:each) do
		@user_collection = double(Datanet::Skel::CollectionMock)
		@mapper = double(Datanet::Skel::MapperMock)
		allow(@mapper).to receive(:collection).with('user')
			.and_return(@user_collection)
    allow(@mapper).to receive(:collection).with('file')
      .and_return(file_collection)

		Datanet::Skel::API.mapper = @mapper
	end

	describe 'GET /' do
		it 'lists collections names' do
			collections = ['a', 'b', 'c']
			expect(@mapper).to receive(:collections).and_return(collections)

			get '/', nil, headers
			expect(last_response.status).to eq 200
			expect(json_response).to eq collections
		end

		it 'lists empty collections names' do
			expect(@mapper).to receive(:collections).and_return(nil)

			get '/', nil, headers
			expect(last_response.status).to eq 200
			expect(json_response).to eq []
		end
	end

	describe 'GET :collection_name' do
		it 'gets non existing collection' do
			expect(@mapper).to receive(:collection).with('non_existing')
			 	.and_raise(Datanet::Skel::CollectionNotFoundException.new)

  			get 'non_existing', nil, headers
  			expect(last_response.status).to eq 404
		end

		it 'gets user collection entities' do
			elements = ['1', '2', '3']
			expect(@user_collection).to receive(:index).and_return(elements)
      allow(@user_collection).to receive(:att_type).with('route_info').and_return(:nil)

			get 'user', nil, headers
			expect(last_response.status).to eq 200
			expect(JSON.parse(last_response.body)).to eq elements
		end

		it 'gets empty user collection entities' do
			expect(@user_collection).to receive(:index).and_return(nil)

			get 'user', nil, headers
			expect(last_response.status).to eq 200
			expect(json_response).to eq []
		end

    context '?search=value' do
      before do
        @user_collection.stub(:attr_type).with('name').and_return(:string)
        @user_collection.stub(:attr_type).with('age').and_return(:number)
        @user_collection.stub(:attr_type).with('tags').and_return(:array)
        @user_collection.stub(:attr_type).with('active').and_return(:boolean)
      end

      it 'gets entities ids using single query element' do
        ids = ['1', '2']
        expect(@user_collection).to receive(:search).with({"name" => "marek"}).and_return(ids)

        get 'user?name=marek', nil, headers
        expect(last_response.status).to eq 200
        expect(json_response).to eq ids
      end

      it 'removes grid_proxy query param and use it to authenticate' do
        ids = ['1', '2']
        expect(@user_collection).to receive(:search).with({"name" => "marek"}).and_return(ids)

        get "user?name=marek&grid_proxy=#{URI::encode(proxy_payload)}"
        expect(last_response.status).to eq 200
      end

      it 'gets entities ids using complex (AND) query' do
        ids = ['1', '3']
        expect(@user_collection).to receive(:search).with({"name" => "marek", "age" => 31.0}).and_return(ids)

        get 'user?name=marek&age=31', nil, headers
        expect(last_response.status).to eq 200
        expect(json_response).to eq ids
      end

      context 'with operator' do
        context 'number' do
          it 'returns all smaller elements (<)' do
            expect(@user_collection).to receive(:search).with("age" => {value: 31.0, operator: :<})

            get 'user?age=%3C31', nil, headers
          end

          it 'returns equals or smaller elements (<=)' do
            expect(@user_collection).to receive(:search).with("age" => {value: 31.0, operator: :<=})

            get 'user?age=%3C%3D31', nil, headers
          end

          it 'returns greater elements (>)' do
             expect(@user_collection).to receive(:search).with("age" => {value: 31.0, operator: :>})

            get 'user?age=%3E31', nil, headers
          end

          it 'returns equals or greater elements (>=)' do
             expect(@user_collection).to receive(:search).with("age" => {value: 31.0, operator: :>=})

            get 'user?age=%3E%3D31', nil, headers
          end

          it 'returns not equals elements (!=)' do
            expect(@user_collection).to receive(:search).with("age" => {value: 31.0, operator: :!=})

            get 'user?age=!%3D31', nil, headers
          end
        end

        context 'string' do
          it 'should ignore number operator' do
            expect(@user_collection).to receive(:search).with("name" => '<name')

            get 'user?name=%3Cname', nil, headers
          end

          it 'returns query with like operator' do
            expect(@user_collection).to receive(:search).with("name" => {value: 'regexp', operator: :regexp})

            get 'user?name=/regexp/', nil, headers
          end
        end

        context 'array' do
          it 'return query with contains operator' do
            expect(@user_collection).to receive(:search).with("tags" => {value: ['1', '2', '3'], operator: :contains})

            get 'user?tags=1,2,3', nil, headers
          end
        end

        context 'boolean' do
          before do
            expect(@user_collection).to receive(:search).with("active" => true)
          end

          it 'converts true string into boolean true' do
            get 'user?active=true', nil, headers
          end

          it 'converts yes string into boolean true' do
            get 'user?active=yes', nil, headers
          end

          it 'converts 1 string into boolean true' do
            get 'user?active=1', nil, headers
          end
        end

        context 'compount query params' do
          before do
            expect(@user_collection).to receive(:search).with("age" => [{value: 2, operator: :>}, {value: 5, operator: :<}])
          end

          it 'creates query with attr equals 2 and smaller than 5' do
            get 'user?age[]=%3E2&age[]=%3C5', nil, headers
          end
        end
      end
    end
	end

	describe 'POST /:collection_name' do
    let(:new_user) { {'first_name' => 'marek', 'age' => 31} }

    it 'adds valid entity into user collection' do
      expect(@user_collection).to receive(:add).with(new_user, nil).and_return(user_id)

      post 'user', new_user.to_json, headers
      expect(last_response.status).to eq 201
      expect(json_response['id']).to eq user_id
    end

		it 'adds invalid entity into user collection' do
			new_user = {'first_name' => 'marek', 'tags' => ['a', 'b', 'c'], 'nrs' => [1, 2, 3]}
			expect(@user_collection).to receive(:add).with(new_user, nil)
				.and_raise(Datanet::Skel::ValidationError.new 'error message')

			post 'user', new_user.to_json, headers
			expect(last_response.status).to eq 422
			expect(last_response.body).to eq 'error message'
    end

    it 'adds entity with files' do
      expect(@user_collection).to receive(:add) do |doc, file_transmition|
        expect(doc["attr"]).to eq "value"
        expect(file_transmition.proxy_payload).to eq proxy_payload
        neigh = file_transmition.files["neighbor"]
        expect(neigh).to_not be_nil
        expect(neigh[:filename]).to eq "picture.jpg"
        expect(neigh[:payload_stream].read).to eq "contents"
        user_id
      end
      expect(@user_collection).to receive(:attr_type).with('attr').and_return(:string)

      post 'user', multipart_stream(:message_json_string), headers_multipart
      expect(last_response.status).to eq 201
      expect(json_response['id']).to eq user_id
    end

    context 'converting form attrs (numbers, integers, arrays)' do
      before do
        expect(@user_collection).to receive(:attr_type).with('first_name').and_return(:string)
      end

      it 'updates integer field basing on schema datatype if multipart request type' do
        expect(@user_collection).to receive(:add).with(new_user, nil).and_return(user_id)
        expect(@user_collection).to receive(:attr_type).with('age').and_return(:integer)

        post 'user', multipart_stream(:message_user), headers_multipart
        expect(last_response.status).to eq 201
        expect(json_response['id']).to eq user_id
      end

      it 'updates integer field basing on schema datatype if multipart request type' do
        user = new_user.dup
        user['age'] = 31.0

        expect(@user_collection).to receive(:add).with(user, nil).and_return(user_id)
        expect(@user_collection).to receive(:attr_type).with('age').and_return(:number)

        post 'user', multipart_stream(:message_user), headers_multipart
        expect(last_response.status).to eq 201
        expect(json_response['id']).to eq user_id
      end

      context 'array fields' do

        let(:new_user_with_array) { {'first_name' => 'marek', 'age' => 31, 'tags' => ['a', 'b', 'c'], 'nrs' => [1, 2, 3]} }

        before do
          expect(@user_collection).to receive(:attr_type).with('age').and_return(:integer)
          expect(@user_collection).to receive(:attr_type).with('tags').and_return(:array)
          expect(@user_collection).to receive(:attr_type).with('nrs').and_return(:array)
        end

        it 'converts into array subtype' do
          expect(@user_collection).to receive(:add).with(new_user_with_array, nil).and_return(user_id)

          post 'user', multipart_stream(:message_user_with_array), headers_multipart
          expect(last_response.status).to eq 201
          expect(json_response['id']).to eq user_id
        end
      end
    end
  end

  describe 'GET /:collection_name/:id' do
    it 'gets existing user entity' do
      user = {'first_name' => 'marek', 'age' => 31}
      expect(@user_collection).to receive(:get).with(user_id).and_return(user)

      get "user/#{user_id}", nil, headers
      expect(last_response.status).to eq 200
      expect(json_response).to eq user
    end

    it 'gets non existing user entity' do
      expect(@user_collection).to receive(:get).with(user_id)
      .and_raise(entity_not_found_error(user_id))

      get "user/#{user_id}", nil, headers
      entity_not_found?(user_id)
    end

    context 'when file entity' do
      before do
        expect(file_collection).to receive(:get_file).with('id', proxy_payload).and_yield('ala ').and_yield('ma ').and_yield('kota')
        allow(file_collection).to receive(:get_filename).with('id').and_return('sample_file.txt')
      end

      it 'gets file' do
        get "file/id", nil, headers
        expect(last_response.body).to eq 'ala ma kota'
      end

      it 'can pass grid_proxy as a query param' do
        get "file/id?grid_proxy=#{URI::encode(proxy_payload)}"
        expect(last_response.status).to eq 200
      end
    end
  end

  describe 'GET /:collection_name/:id/:attr_name' do
    it 'gets existing user entity attribute' do
      user = {'first_name' => 'marek', 'age' => 31}
      expect(@user_collection).to receive(:get).with(user_id).and_return(user)

      get "user/#{user_id}/first_name", nil, headers
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'marek'
    end

    it 'gets non existing user entity attribute' do
      user = {'first_name' => 'marek', 'age' => 31}
      expect(@user_collection).to receive(:get).with(user_id).and_return(user)

      get "user/#{user_id}/non_existing", nil, headers
      expect(last_response.status).to eq 404
      expect(json_response).to eq({'message' => "Attribute non_existing not found in #{user_id} user entity"})
    end
  end

	describe 'DELETE /:collection_name/:id' do
		it 'deletes existing user entity' do
			expect(@user_collection).to receive(:remove).with(user_id)

			delete "user/#{user_id}", nil, headers
			expect(last_response.status).to eq 200
		end

		it 'deletes non existing user entity' do
			expect(@user_collection).to receive(:remove).with(user_id)
				.and_raise(entity_not_found_error(user_id))

			delete "user/#{user_id}", nil, headers
			entity_not_found?(user_id)
		end
	end

	describe 'POST /:collection_name/:id' do
		it 'updates existing user entity' do
			update = {'first_name' => 'Marek'}
			expect(@user_collection).to receive(:update).with(user_id, update)

			post "user/#{user_id}", update.to_json, headers
			expect(last_response.status).to eq 201
		end

		it 'updates non existing user entity' do
			doc = {'not' => 'important'}
			expect(@user_collection).to receive(:update).with(user_id, doc)
				.and_raise(entity_not_found_error(user_id))

			post "user/#{user_id}", doc.to_json, headers
			entity_not_found?(user_id)
		end

		it 'updates existing user entity with not correct values' do
			mandatory_parameter_set_to_nil = {'first_name' => nil}
			expect(@user_collection).to receive(:update).with(user_id, mandatory_parameter_set_to_nil).and_raise(Datanet::Skel::ValidationError.new)

			post "user/#{user_id}", mandatory_parameter_set_to_nil.to_json, headers
			expect(last_response.status).to eq 422
			# TODO check validation error message
		end
	end

  describe 'PUT /:collection_name/:id' do
   it 'overwites existing user entity' do
      updated_user = {'first_name' => 'marek', 'age' => 31}
      expect(@user_collection).to receive(:replace).with(user_id, updated_user)

      put "user/#{user_id}", updated_user.to_json, headers
      expect(last_response.status).to eq 200
   end

   it 'overwrites non existing user entity' do
      doc = {'not' => 'important'}
      expect(@user_collection).to receive(:replace).with(user_id, doc)
      .and_raise(entity_not_found_error(user_id))

      put "user/#{user_id}", doc.to_json, headers
      entity_not_found?(user_id)
   end

   it 'overwrites existing user entity with not correct values' do
      update_without_mandatory_param = {'age' => 31}
      expect(@user_collection).to receive(:replace).with(user_id, update_without_mandatory_param).and_raise(Datanet::Skel::ValidationError.new)

      put "user/#{user_id}", update_without_mandatory_param.to_json, headers
      expect(last_response.status).to eq 422
      # TODO check validation error message
   end
  end

	describe 'GET /:collection_name.schema' do
		it 'returns schema json' do
			schema = {
				"type" => "object",
				"properties" => {
					"name" => {"type" => "string", "required" => true},
					"age" => {"type" => "integer"}
				}
			}
			expect(@user_collection).to receive(:schema).and_return(schema)

			get 'user.schema', nil, headers
			expect(last_response.status).to eq 200
			expect(json_response).to eq schema
		end
		it 'return 404 when schema is not found' do
			expect(@mapper).to receive(:collection).with('non_existing').and_raise(Datanet::Skel::CollectionNotFoundException.new)

			get 'non_existing.schema', nil, headers
			expect(last_response.status).to eq 404
		end
	end

	def entity_not_found?(id)
		expect(last_response.status).to eq 404
		expect(json_response).to eq({'message' => entity_not_found_message(id)})
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