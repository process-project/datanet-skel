require 'spec_helper'

describe Datanet::Skel::RepositoryAuth do

  before do
    subject.repo_secret_path = File.join(auth_dir, 'repo_secret')
    subject.settings = AuthSettings
  end

  context 'public repository' do
    before do
      File.write(subject.settings.config_file, 'repository_type: public')
      subject.settings.reload!
    end

    it 'allows anonymous access' do
      expect(subject.authenticate(nil, nil)).to eq true
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

    it 'authenticate user if is on owners list and correct password' do
      subject.authenticator.stub(:authenticate).with('marek', 'pass').and_return(true)
      expect(subject.authenticate('marek', 'pass')).to eq true
    end

    it 'return false (Unauthorized) for owner with wrong password' do
      subject.authenticator.stub(:authenticate).with('marek', 'wrong_pass').and_return(false)
      expect(subject.authenticate('marek', 'wrong_pass')).to eq false
    end

    it 'return false (Unauthorized) for non repository owner' do
      expect(subject.authenticate('not_owner', 'pass')).to eq false
    end

    it 'return false (Unauthorized) when owners list empty' do
      File.write(subject.settings.config_file, <<-CONFIG
repository_type: private
owners:
      CONFIG
      )
      subject.settings.reload!
      expect(subject.authenticate('marek', 'pass')).to eq false
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