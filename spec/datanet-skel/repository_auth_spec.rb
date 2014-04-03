require 'spec_helper'

describe Datanet::Skel::RepositoryAuth do

  before do
    subject.repo_secret_path = File.join(auth_dir, 'repo_secret')
    subject.settings = AuthSettings
  end

  it 'allow to access anyone with valid proxy' do
    allow(subject.authenticator).to receive(:authenticate).with('creds').and_return(true)

    subject.authenticate!('creds')
  end

  it 'unauthenticates when proxy is nil' do
    expect { subject.authenticate!(nil) }.to raise_error(Datanet::Skel::Unauthenticated)
  end

  it 'unauthenticates when proxy is empty' do
    expect { subject.authenticate!('') }.to raise_error(Datanet::Skel::Unauthenticated)
  end

  it 'unauthenticates when proxy is invalid' do
    allow(subject.authenticator).to receive(:authenticate).with('wrongcreds').and_return(false)

    expect { subject.authenticate!('wrongcreds') }.to raise_error(Datanet::Skel::Unauthenticated)
  end

  context 'public repository' do
    before do
      File.write(subject.settings.config_file, 'repository_type: public')
      subject.settings.reload!
    end

    it 'allows to access any valid user' do
      subject.authorize!('creds')
    end
  end

  context 'private repository' do
    before do
      File.write(subject.settings.config_file, <<-CONFIG
repository_type: private
owners: ['marek', 'daniel']
      CONFIG
      )
      subject.settings.reload!
      subject.authenticator = double
    end

    it 'authorize repo owners' do
      expect(subject.authenticator).to receive(:username).with('creds').and_return('marek')
      subject.authorize!('creds')
    end

    it 'unauthorize other user' do
      expect(subject.authenticator).to receive(:username).with('creds').and_return('wojtek')
      expect { subject.authorize!('creds') }.to raise_error(Datanet::Skel::Unauthorized)
    end

    it 'return false (Unauthorized) when owners list empty' do
      File.write(subject.settings.config_file, <<-CONFIG
repository_type: private
owners:
      CONFIG
      )
      subject.settings.reload!
      expect(subject.authenticator).to receive(:username).with('not_owner_creds').and_return('not_owner')
      expect { subject.authorize!('not_owner_creds') }.to raise_error(Datanet::Skel::Unauthorized)
    end
  end

  context 'update authorization configuration' do
    before do
      File.write(subject.settings.config_file, 'other_prop: value')
      subject.settings.reload!
    end

    it 'updates repository type' do
      subject.repository_type = :private
      config_file_content = File.read(subject.settings.config_file).chomp

      expect(config_file_content).to include('repository_type: private')
      expect(subject.settings.repository_type).to eq 'private'
    end

    it 'updates owners list' do
      subject.owners = ["marek", "daniel"]
      config_file_content = File.read(subject.settings.config_file).chomp

      expect(config_file_content).to include('owners:')
      expect(config_file_content).to include('- marek')
      expect(config_file_content).to include('- daniel')

      expect(subject.settings.owners).to eq ['marek', 'daniel']
    end

    it 'does not overwrite other properties' do
      subject.repository_type = :private
      config_file_content = File.read(subject.settings.config_file).chomp

      expect(config_file_content).to include('other_prop: value')
    end

    it 'updates cors origins' do
      new_origins = ['a.pl', 'b.pl']
      cors = double
      subject.cors = cors
      expect(cors).to receive(:origins).with(*new_origins)

      subject.cors_origins = new_origins
      config_file_content = File.read(subject.settings.config_file).chomp

      expect(config_file_content).to include('cors_origins:')
      expect(config_file_content).to include('- a.pl')
      expect(config_file_content).to include('- b.pl')

      expect(subject.settings.cors_origins).to eq ['a.pl', 'b.pl']
    end
  end

  describe 'admin authorization' do
    it 'returns true if valid admin token' do
      expect(subject.admin?('secret')).to eq true
    end

    it 'returns false if admin token is not valid' do
      expect(subject.admin?('invalid_token')).to eq false
    end
  end

  context '#configuration' do
    before do
      File.write(subject.settings.config_file, <<-CONFIG
repository_type: private
owners: ['marek', 'daniel']
      CONFIG

      )
      subject.settings.reload!
    end

    it 'returns configuration hash' do
      expect(subject.configuration).to eq({'repository_type' => 'private', 'owners' => ['marek', 'daniel'] })
    end
  end
end