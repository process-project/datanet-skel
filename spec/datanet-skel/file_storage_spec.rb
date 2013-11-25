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

  def conn
    @conn ||= double
  end

  def dir
    @dir ||= double
  end

  it "should store payload into newly created file - datanet directory not created" do

    # doubles
    file = double()
    inner_file = double()
    entry = double(name: @folder_name)

    # stubs
    conn.stub(:sftp_user).and_return(@user)
    conn.stub(:in_session).and_yield(sftp)
    sftp.stub(:dir).and_return(dir)

    #expectations
    dir.should_receive(:foreach).with("#{@base_path}/#{@user}").and_yield(entry)

    sftp.should_receive(:upload!) do |payload, path|
      path.should match("#{@full_path}/.*")
    end

    # initialization
    storage = Datanet::Skel::FileStorage.new()

    # calls
    storage.store_payload(conn, @payload).should match("#{@full_path}/.*")

  end

  it "should store payload into newly created file - datanet directory created" do

    # doubles
    file = double()
    inner_file = double()

    # stubs
    conn.stub(:sftp_user).and_return(@user)
    conn.stub(:in_session).and_yield(sftp)
    sftp.stub_chain(:dir, :foreach)
    sftp.stub(:file).and_return(file)

    #expectations
    sftp.should_receive(:mkdir!).with("#{@base_path}/#{@user}/#{@folder_name}")
    sftp.should_receive(:upload!) do |payload, path|
      path.should match("#{@full_path}/.*")
    end

    # initialization
    storage = Datanet::Skel::FileStorage.new()

    # calls
    storage.store_payload(conn, @payload).should match("#{@full_path}/.*")

  end

  #it "saves file" do
  #  conn = Datanet::Skel::SftpConnection.new("zeus.cyfronet.pl", TestSettings.myuser, TestSettings.mypass)
  #  storage = Datanet::Skel::FileStorage.new()
  #
  #  path = storage.generate_path conn
  #  storage.store_payload(conn, "dasdasdasda", path)
  #  storage.delete_file(conn, path)
  #end

end



#
#require 'net/sftp'
#
#describe "SFTP" do
#
#  before(:all) do
#    @ssh = Net::SSH.start(TestSettings.sftp_host, TestSettings.sftp_user, :password => TestSettings.sftp_password, :keys => [] )
#    @sftp = @ssh.sftp
#    @path = "/mnt/auto/people/#{TestSettings.sftp_user}/.datanet_test"
#  end
#
#  it "should list home directory" do
#    result = @ssh.exec!("ls -l")
#    result.should_not == nil
#
#    #puts result
#  end
#
#  it "should open home directory" do
#    @ssh.sftp.opendir("/mnt/auto/people/#{TestSettings.sftp_user}") do |response|
#      response.ok?.should == true
#    end
#  end
#
#  it "should not open not existing file" do
#    @ssh.sftp.opendir("/mnt/auto/people/#{TestSettings.sftp_user}/somerandomstring1") do |response|
#      response.ok?.should == false
#    end
#  end
#
#  it "should create .datanet_test directory and remove it" do
#    @sftp.mkdir!(@path)
#    @sftp.file.directory?(@path).should == true
#    @sftp.rmdir!(@path)
#  end
#
#  it "should create file in .datanet_test directory and remove it" do
#    @sftp.mkdir!(@path)
#    @sftp.file.directory?(@path).should == true
#    file_path = "#{@path}/test_file_name"
#    file = @sftp.file.open(file_path, "w")
#    file.puts("anystring")
#    @sftp.remove!(file_path)
#  end
#
#  after(:all) do
#    @ssh.close
#  end
#
#end
