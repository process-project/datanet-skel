require 'spec_helper'
require 'datanet-skel/exceptions'
require 'datanet-skel/file_transmition'

describe Datanet::Skel::MapperDecorator do

  def mapper
    @mapper ||= double(Datanet::Skel::MapperMock)
  end

  def file_storage
    @file_storage ||= double
  end

  def app
    app = Datanet::Skel::MapperDecorator.new(mapper)
    app.model_location = @model_location
    app
  end

  describe 'collections method' do
    it 'lists registered collections' do
      @model_location = models_dir

      app.collections.should == ['address', 'book', 'user', 'with_file', 'with_files']
    end

    it 'raises exception while model directory does not exist' do
      @model_location = '/non/existing/location'

      expect {
        app.collections
      }.to raise_error(Datanet::Skel::WrongModelLocationError, 'Wrong models directory location')
    end

    it 'throws exception while collections directory does not contains schemas' do
      @model_location = empty_models_dir

      expect {
        app.collections
      }.to raise_error(Datanet::Skel::WrongModelLocationError, 'No models in selected models directory')
    end
  end

  describe 'collection method' do
    it 'get existing collection' do
      @model_location = models_dir
      mapper.should_receive(:collection).with(any_args())
          .and_return(Object.new)

      app.collection('user').should be_an_instance_of(Datanet::Skel::EntityDecorator)
    end

    it 'throws exception while getting non existing collection' do
      @model_location = models_dir

      expect {
        app.collection('not_existing')
      }.to raise_error(Datanet::Skel::CollectionNotFoundException, 'Entity not_existing not found')
    end
  end
end

describe Datanet::Skel::EntityDecorator do

  def entity
    @entity ||= double(Datanet::Skel::CollectionMock)
  end

  def file_storage
    @file_storage ||= double
  end

  def mapper_decorator
    @mapper_decorator ||= double
  end

  def proxy_payload
    @proxy_payload ||= double
  end

  def app model_name
    Datanet::Skel::EntityDecorator.new(entity, model_path(model_name), file_storage, mapper_decorator)
  end

  describe 'add method' do
    it 'adds new entity when json is valid according to give schema' do
      new_user = {'first_name' => 'marek', 'last_name' => 'k', 'age' => 31, 'other' => 'something else'}
      new_user_id = '1234'

      entity.should_receive(:add).with(new_user, {}).and_return(new_user_id)

      app('user').add(new_user).should == new_user_id
    end

    it 'adds valid entity with reference' do
      new_book = {'title' => 'book1', 'authId' => 'existingId', 'blurb' => 'description'}
      new_book_id = '1234f'

      entity.should_receive(:add).with(new_book,
        {'authId' => 'author', 'publisherId' => 'publisher'}).and_return(new_book_id)

      app('book').add(new_book).should == new_book_id
    end

    it 'throws exception when json is not valid according to given schema' do
      not_valid_user = {'first_name' => 'marek', 'age' => 31, 'other' => 'something else'}

      expect {
        app('user').add(not_valid_user)
      }.to raise_error do |error|
        expect(error).to be_a Datanet::Skel::ValidationError
        expect(error.message).to include "The property '#/' did not contain a required property of 'last_name'"
      end
    end

    it 'throws exception when adding a file together with metadata file reference attribute' do
      valid_entity = {'first_name' => 'marek', 'avatar' => 'this_is_a_cause_of_failure' }
      files = { 'avatar' => { :filename => 'marek_photo.jpg', :payload => '' }}

      file_transmition = Datanet::Skel::FileTransmition.new(proxy_payload, files)

      expect {
        app('with_file').add(valid_entity, file_transmition)
      }.to raise_error do |error|
        expect(error).to be_a Datanet::Skel::ValidationError
        expect(error.message).to include 'File upload conflicts with metadata attribute \'avatar\''
      end
    end

    it 'adds valid entity with files' do
      valid_entity = {'first_name' => 'marek'}

      payload = double

      files = { 'avatar' => { :filename => 'marek_photo.jpg', :payload_stream => payload }}
      file_transmition = Datanet::Skel::FileTransmition.new(proxy_payload, files)

      file_path = "/some/path/on/sftp"
      file_storage.should_receive(:generate_path).and_return(file_path)
      file_storage.should_receive(:store_payload).with(kind_of(GP::Proxy), payload, file_path).and_return(file_path)

      file_collection = double
      mapper_decorator.should_receive(:collection).with('file').and_return(file_collection)

      file_id = "filei123"
      file_collection.should_receive(:add).and_return(file_id)

      new_entity_id = "id_123"
      entity.should_receive(:add).with(valid_entity, {'attachment_id'=>'file'}).and_return(new_entity_id)

      app('with_file').add(valid_entity, file_transmition).should == new_entity_id
    end

    it 'sanitize file name' do
      valid_entity = {'first_name' => 'marek'}
      payload = double
      files = { 'avatar' => { :filename => "marek\nphoto.jpg", :payload_stream => payload }}
      file_transmition = Datanet::Skel::FileTransmition.new(proxy_payload, files)
      file_path = "/some/path/on/sftp"
      allow(file_storage).to receive(:generate_path).and_return(file_path)
      allow(file_storage).to receive(:store_payload).with(kind_of(GP::Proxy), payload, file_path).and_return(file_path)
      file_collection = double
      allow(mapper_decorator).to receive(:collection).with('file').and_return(file_collection)
      new_entity_id = "id_123"
      allow(entity).to receive(:add).with(valid_entity, {'attachment_id'=>'file'}).and_return(new_entity_id)
      file_id = "filei123"
      added_file_name = nil
      allow(file_collection).to receive(:add) do |params|
        added_file_name = params['file_name']
      end.and_return(file_id)

      app('with_file').add(valid_entity, file_transmition)

      expect(added_file_name).to eq 'marek_photo.jpg'
    end

    it 'adds one file succesfully but fails on adding second' do
      valid_entity = {'first_name' => 'marek', 'avatar2' => 'this_is_a_cause_of_failure' }

      payload = double

      files = { 'avatar' => { :filename => 'marek_photo.jpg', :payload_stream => payload },
       'avatar2' => { :filename => 'marek_photo2.jpg', :payload_stream => payload }
      }
      file_transmition = Datanet::Skel::FileTransmition.new(proxy_payload, files)

      file_path = "/some/path/on/sftp"
      file_storage.should_receive(:generate_path).and_return(file_path)
      file_storage.should_receive(:store_payload).with(kind_of(GP::Proxy), payload, file_path).and_return(file_path)

      file_collection = double
      mapper_decorator.should_receive(:collection).with('file').and_return(file_collection)

      file_entity_id = "file11"
      file_collection.should_receive(:add).and_return(file_entity_id)

      # on rollback
      mapper_decorator.should_receive(:collection).with('file').and_return(file_collection)
      file_collection.should_receive(:remove).with(file_entity_id)
      file_storage.should_receive(:delete_file)

      expect{
        app('with_file').add(valid_entity, file_transmition)
      }.to raise_error
    end

  end

  describe 'replace entity' do
    it 'replaces valid json document' do
      updated_user = {'first_name' => 'marek', 'last_name' => 'k', 'age' => 31, 'other' => 'something else'}
      user_id = '1234'

      entity.should_receive(:replace).with(user_id, updated_user, {})

      app('user').replace(user_id, updated_user)
    end

    it 'replaces valid json document with reference' do
      updated_book = {'title' => 'book1', 'authId' => 'existingId', 'blurb' => 'description'}
      book_id = '1234fd'

      entity.should_receive(:replace).with(book_id, updated_book,
        {'authId' => 'author', 'publisherId' => 'publisher'})

      app('book').replace(book_id, updated_book)
    end

    it 'throws exception when replace json is not valid' do
      not_valid_updated_user = {'first_name' => 'marek', 'age' => 31, 'other' => 'something else'}
      user_id = '1234'

      expect {
        app('user').replace(user_id, not_valid_updated_user)
      }.to raise_error do |error|
        expect(error).to be_a Datanet::Skel::ValidationError
        expect(error.message).to include "The property '#/' did not contain a required property of 'last_name'"
      end
    end

    it 'throws exception while entity not found exception' do
      updated_user = {'first_name' => 'marek', 'last_name' => 'k', 'age' => 31, 'other' => 'something else'}
      non_existing_id = '1235'

      entity.should_receive(:replace).with(non_existing_id, updated_user, {})
      .and_raise(Datanet::Skel::EntityNotFoundException.new)

      expect {
        app('user').replace(non_existing_id, updated_user)
      }.to raise_error(Datanet::Skel::EntityNotFoundException)
    end
  end

  describe 'update entity' do
    it 'updates entity with valid values' do
      updated_values = {'first_name' => 'Marek', 'another' => 'value'}
      user = {'first_name' => 'marek', 'last_name' => 'k', 'age' => 31}
      user_id = '1234'

      entity.should_receive(:get).with(user_id).and_return(user)
      entity.should_receive(:update).with(user_id, updated_values, {})

      app('user').update(user_id, updated_values)
    end

    it 'updates entity with valid values with reference' do
      book = {'title' => 'book1', 'authId' => 'existingId', 'blurb' => 'description'}
      updated_book = {'authId' => 'updatedId', 'blurb' => ' updated description'}
      book_id = '1234fd'

      entity.should_receive(:get).with(book_id).and_return(book)
      entity.should_receive(:update).with(book_id, updated_book,
        {'authId' => 'author', 'publisherId' => 'publisher'})

      app('book').update(book_id, updated_book)
    end

    it 'throws exception while nulling required fields' do
      wrong_updated_values = {'first_name' => nil, 'another' => 'value'}
      user = {'first_name' => 'marek', 'last_name' => 'k', 'age' => 31}
      user_id = '1234'

      entity.should_receive(:get).with(user_id).and_return(user)

      expect {
        app('user').update(user_id, wrong_updated_values)
      }.to raise_error do |error|
        expect(error).to be_a Datanet::Skel::ValidationError
        expect(error.message).to include "The property '#/first_name' of type null did not match the following type: string"
      end
    end
  end

  describe 'schema' do
    it 'gets schema content as json object' do
      @model_location = models_dir
      schema_content = File.read(File.join(@model_location, 'user.json'))
      user_schema = JSON.parse(schema_content)
      app('user').schema.should == user_schema
    end
  end

  describe 'attribute datatype' do
    before { @model_location = models_dir }

    it 'knows strings' do
      attr_type = app('user').attr_type('first_name')
      expect(attr_type).to eq :string
    end

    it 'knows integers' do
      attr_type = app('user').attr_type('age')
      expect(attr_type).to eq :integer
    end

    it 'knows numbers' do
      attr_type = app('user').attr_type('weight')
      expect(attr_type).to eq :number
    end

    it 'knows array' do
      attr_type = app('book').attr_type('tags')
      expect(attr_type).to eq :array
    end

    it 'knows boolean' do
      attr_type = app('book').attr_type('published')
      expect(attr_type).to eq :boolean
    end
  end

  describe 'delete entity' do
    let(:file_collection) { double('file collection') }

    before do
      allow(mapper_decorator)
        .to receive(:collection)
          .with('file').and_return(file_collection)
    end

    it 'deletes entity without file reference' do
      id = 'entity_id'
      allow(entity).to receive(:get).and_return({})
      expect(entity).to receive(:remove).with(id)

      app('user').remove(id, 'proxy')
    end

    it 'deletes entity with single file reference' do
      id = 'entity_id'
      file_id = 'file_id'
      allow(entity).to receive(:get).and_return({
        'first_name' => 'not important',
        'attachment_id' => file_id
      })

      expect(entity).to receive(:remove).with(id)
      expect(file_collection).to receive(:remove).with(file_id, 'proxy')

      app('with_file').remove(id, 'proxy')
    end

    it 'deletes only entity when file reference is empty' do
      id = 'entity_id'
      file_id = 'file_id'
      allow(entity).to receive(:get).and_return({
        'first_name' => 'not important'
      })

      expect(entity).to receive(:remove).with(id)
      expect(file_collection).not_to receive(:remove)

      app('with_file').remove(id, 'proxy')
    end

    it 'deletes entity with files array references' do
      id = 'entity_id'
      file1_id = 'file1_id'
      file2_id = 'file2_id'
      allow(entity).to receive(:get).and_return({
        'first_name' => 'not important',
        'attachment_ids' => [file1_id, file2_id]
      })
      expect(entity).to receive(:remove).with(id)
      expect(file_collection).to receive(:remove).with(file1_id, 'proxy')
      expect(file_collection).to receive(:remove).with(file2_id, 'proxy')

      app('with_files').remove(id, 'proxy')
    end
  end
end