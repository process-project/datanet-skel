require 'spec_helper'

describe Datanet::Skel::RepositoryAuthorization do

  context 'public repository' do
    pending 'allows anonymous access'
  end

  context 'private repository' do
    pending 'authenticate user if is on owners list'
    pending 'return 403 (Unauthorized) for non repository owner'
  end

  pending 'update authorization configuration'
end