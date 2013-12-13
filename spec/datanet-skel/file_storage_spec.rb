require 'spec_helper'
require 'datanet-skel/file_storage'

describe Datanet::Skel::FileStorage do

  let(:user) { 'plguser' }
  let(:base_path) { '/mnt/auto/people' }
  let(:folder_name) { '.datanet' }
  let(:full_path) { "#{base_path}/#{user}/#{folder_name}" }
  let(:gftp_client) { double }
  let(:proxy) { double(proxy_payload: 'proxy payload', username: user) }

  before do
    GFTP::Client.stub(:new).and_return gftp_client
  end

  subject { Datanet::Skel::FileStorage.new(base_path, folder_name) }

  describe '#store_payload' do

  end

  describe '#delete_file' do
    let(:file_path) { "#{full_path}/file_to_delete" }

    context 'when file exists' do
      before do
        expect(gftp_client).to receive(:delete).with(file_path).and_yield(true)
      end

      it 'deletes file' do
        subject.delete_file(proxy, file_path)
      end
    end

    context 'when file does not exists' do
      before do
        expect(gftp_client).to receive(:delete).with(file_path).and_yield(false)
      end

      it 'throws file storage exception' do
        expect {
          subject.delete_file(proxy, file_path)
        }.to raise_error(Datanet::Skel::FileStorageException, "Unable to delete file #{file_path}")
      end
    end
  end

  describe '#get_file' do

  end

  # TODO

  # it "should store payload into newly created file - datanet directory not created" do

  #   # doubles
  #   file = double()
  #   inner_file = double()
  #   entry = double(name: @folder_name)

  #   # stubs
  #   allow(proxy).to receive(:username).and_return(@user)

  #   proxy.stub(:sftp_user).and_return(@user)

  #   sftp.should_receive(:upload!) do |payload, path|
  #     path.should match("#{@full_path}/.*")
  #   end

  #   # initialization
  #   storage = Datanet::Skel::FileStorage.new()

  #   # calls
  #   storage.store_payload(proxy, @payload).should match("#{@full_path}/.*")

  # end

  # it "should store payload into newly created file - datanet directory created" do

  #   # doubles
  #   file = double()
  #   inner_file = double()

  #   # stubs
  #   proxy.stub(:username).and_return(@user)
  #   proxy.stub(:in_session).and_yield(sftp)
  #   sftp.stub_chain(:dir, :foreach)
  #   sftp.stub(:file).and_return(file)

  #   #expectations
  #   sftp.should_receive(:mkdir!).with("#{@base_path}/#{@user}/#{@folder_name}")
  #   sftp.should_receive(:upload!) do |payload, path|
  #     path.should match("#{@full_path}/.*")
  #   end

  #   # initialization
  #   storage = Datanet::Skel::FileStorage.new()

  #   # calls
  #   storage.store_payload(proxy, @payload).should match("#{@full_path}/.*")

  # end

  #it "saves file" do
  #  proxy = Datanet::Skel::Sftpproxyection.new("zeus.cyfronet.pl", TestSettings.myuser, TestSettings.mypass)
  #  storage = Datanet::Skel::FileStorage.new()
  #
  #  path = storage.generate_path proxy
  #  storage.store_payload(proxy, "dasdasdasda", path)
  #  storage.delete_file(proxy, path)
  #end

end