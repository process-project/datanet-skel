require 'spec_helper'

describe Datanet::Skel::PortalAuthenticatable do

  def auth
    @auth ||= Datanet::Skel::PortalAuthenticatable.new(TestSettings.portal_base_url, TestSettings.portal_shared_key)
  end

  it 'logs into portal API with proper credentials' do
    status = auth.authenticate(TestSettings.portal_test_user, TestSettings.portal_test_password)
    status.should be_true
  end

  it 'tries to log into portal API with wrong credentials and fails' do
    status = auth.authenticate(TestSettings.portal_test_user, "wrong+password")
    status.should be_false
  end

  it 'tries to log into portal API with wrong credentials and fails' do
    status = auth.authenticate("wrong+user", TestSettings.portal_test_password)
    status.should be_false
  end

end

