require 'spec_helper'
require 'datanet-skel/exceptions'

describe Datanet::Skel::MapperDecorator do

  def mapper
    @mapper ||= mock(Datanet::Skel::MapperMock)
  end

  def app
    app = Datanet::Skel::MapperDecorator.new mapper
    app.model_location = @model_location
    app
  end

  describe 'collections method' do
    it 'lists registered collections' do
      @model_location = models_dir

      app.collections.should == ['address', 'book', 'user']
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
    @entity ||= mock(Datanet::Skel::CollectionMock)
  end

  def app model_name
    Datanet::Skel::EntityDecorator.new entity, model_path(model_name)
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
      }.to raise_error(Datanet::Skel::ValidationError, 'Wrong json format')
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
      }.to raise_error(Datanet::Skel::ValidationError, 'Wrong json format')
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
      }.to raise_error(Datanet::Skel::ValidationError, 'Wrong json format')
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
end