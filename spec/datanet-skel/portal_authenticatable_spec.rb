require 'spec_helper'
require 'datanet-skel/exceptions'
require 'settings'
require 'datanet-logger'

describe Datanet::Skel::PortalAuthenticatable do

	def auth
    @auth = Datanet::Skel::PortalAuthenticatable.new(Settings.portal_base_url, Settings.portal_shared_key) unless @auth != nil
	end

  it 'logs into portal API' do
    status = auth.plgrid_portal_user_check(Settings.portal_test_user,Settings.portal_test_password)
    status.should == true
  end

end

