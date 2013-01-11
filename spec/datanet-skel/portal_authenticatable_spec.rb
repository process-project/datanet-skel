require 'spec_helper'
require 'datanet-skel/exceptions'
require 'settings'

describe Datanet::Skel::PortalAuthenticatable do

	def auth
    Datanet::Skel::PortalAuthenticatable.PORTAL_BASE_URL = Settings.portal_base_url
    Datanet::Skel::PortalAuthenticatable.PORTAL_SHARED_KEY = Settings.portal_shared_key
    auth = Datanet::Skel::PortalAuthenticatable.new
	end

  it 'logs into portal API' do
    auth.plgrid_portal_auth(Settings.user,Settings.Password)
  end

end

