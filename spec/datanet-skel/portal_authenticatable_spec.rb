require 'spec_helper'

describe Datanet::Skel::PortalAuthenticatable do

  def auth
    @auth ||= Datanet::Skel::PortalAuthenticatable.new(TestSettings.portal_base_url, TestSettings.portal_shared_key)
  end

  describe '#authenticate' do
    it 'logs into portal API with proper credentials' do
      status = auth.authenticate({
        login: TestSettings.portal_test_user,
        password: TestSettings.portal_test_password
      })
      status.should be_true
    end

    it 'tries to log into portal API with wrong credentials and fails' do
      status = auth.authenticate({
        login: TestSettings.portal_test_user,
        password: "wrong+password"
      })
      status.should be_false
    end

    it 'tries to log into portal API with wrong credentials and fails' do
      status = auth.authenticate({
        login: "wrong+user",
        password: TestSettings.portal_test_password
      })
      status.should be_false
    end
  end

  describe '#username' do
    it 'returns username from creds' do
      username = auth.username({
        login: TestSettings.portal_test_user,
        password: TestSettings.portal_test_password
      })
      expect(username).to eq TestSettings.portal_test_user
    end
  end
end

