require 'spec_helper'
require 'datanet-skel/exceptions'
require 'settings'
require 'datanet-logger'

describe Datanet::Skel::PortalAuthenticatable do

	def auth
    @auth = Datanet::Skel::PortalAuthenticatable.new(Settings.portal_base_url, Settings.portal_shared_key) unless @auth != nil
	end

  it 'logs into portal API with proper credentials' do
    status = auth.authenticate(Settings.portal_test_user, Settings.portal_test_password)
    status.should == true
  end

  it 'tries to log into portal API with wrong credentials and fails' do
    status = auth.authenticate(Settings.portal_test_user, "wrong+password")
    status.should == false
  end

  it 'tries to log into portal API with wrong credentials and fails' do
    status = auth.authenticate("wrong+user", Settings.portal_test_password)
    status.should == false
  end

end

