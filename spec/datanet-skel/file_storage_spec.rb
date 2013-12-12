require 'spec_helper'
require 'datanet-skel/file_storage'

describe Datanet::Skel::FileStorage do

  before(:all) do
    @user = "plguser"
    @base_path = "/mnt/auto/people"
    @folder_name = ".datanet"
    @full_path = "#{@base_path}/#{@user}/#{@folder_name}"
    @payload = "sample payload"
  end

  def sftp
    @sftp ||= double
  end

  def proxy
    @proxy ||= double
  end

  def dir
    @dir ||= double
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