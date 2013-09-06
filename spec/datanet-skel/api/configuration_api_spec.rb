  require 'spec_helper'

describe Datanet::Skel::ConfigurationApi do
  include Rack::Test::Methods
  include ApiHelpers

  def app
    Datanet::Skel::API
  end

  def authorized_path
    '/_configuration?private_token=secret'
  end

  before do
    Datanet::Skel::API.auth = double
    Datanet::Skel::API.auth.stub(:configuration).and_return({repository_type: :private, owners: ['marek', 'daniel']})
    Datanet::Skel::API.auth.stub(:admin?).with('secret').and_return(true)
    Datanet::Skel::API.auth.stub(:admin?).with(nil).and_return(false)
  end

  describe 'GET _configuration' do
    context 'when auth defined' do
      it 'returns configuration' do
        get authorized_path
        expect(last_response.status).to eq 200
        json_response.should == {'repository_type' => 'private', 'owners' => ['marek', 'daniel']}
      end

      it 'returns 401 (Unauthorized) when no private_token' do
        get '/_configuration'
        expect(last_response.status).to eq 401
      end
    end

    context 'when auth is nil' do
      before { Datanet::Skel::API.auth = nil }

      it 'return 404 for getting configuration' do
        get '/_configuration'
        expect(last_response.status).to eq 404
      end
    end
  end

  describe 'PUT _configuration' do
    context 'when auth defined' do
      it 'updates repository repository_type' do
        Datanet::Skel::API.auth.should_receive(:repository_type=).with(:private)

        put authorized_path, {repository_type: :private}
        expect(last_response.status).to eq 200
      end

      it 'updates owners list' do
        owners = ['marek', 'daniel']
        Datanet::Skel::API.auth.should_receive(:owners=).with(owners)

        put authorized_path, {owners: owners}
        expect(last_response.status).to eq 200
      end

      it 'returns 401 (Unauthorized) when no private_token' do
        put '/_configuration'
        expect(last_response.status).to eq 401
      end
    end

    context 'when auth is nil' do
      before { Datanet::Skel::API.auth = nil }

      it 'return 404 for updating configuration' do
        put '/_configuration'
        expect(last_response.status).to eq 404
      end
    end
  end
end