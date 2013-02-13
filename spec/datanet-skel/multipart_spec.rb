require 'rack/utils'
require 'rack/mock'
require 'datanet-skel/multipart'
require "rspec"

describe Rack::Multipart do

  def multipart_fixture(name, boundary = "AaB03x")
    file = multipart_file(name)
    data = File.open(file, 'rb') { |io| io.read }

    type = "multipart/form-data; boundary=#{boundary}"
    length = data.respond_to?(:bytesize) ? data.bytesize : data.size

    { "CONTENT_TYPE" => type,
      "CONTENT_LENGTH" => length.to_s,
      :input => StringIO.new(data) }
  end

  def multipart_file(name)
    File.join(File.dirname(__FILE__), "multipart", name.to_s)
  end

  it "parses multipart upload with file #{:message_json_file}" do
    env = Rack::MockRequest.env_for("/", multipart_fixture(:message_json_file))
    params = Rack::Utils::Multipart.parse_multipart(env)
    obj = Datanet::Skel::Multipart.new(params)
    obj.files["neighbor"][:payload].should == "contents"
    obj.files["neighbor"][:filename].should == "picture.jpg"
    obj.files["neighbor2"][:payload].should == "contents"
    obj.files["neighbor2"][:filename].should == "picture2.jpg"
    obj.files["neighbor3"].should be_nil
    obj.metadata.should_not be_nil
    obj.metadata.should be_an_instance_of String
  end

  it "parse multipart upload with file #{:message_json_string}" do
    env = Rack::MockRequest.env_for("/", multipart_fixture(:message_json_string))
    params = Rack::Utils::Multipart.parse_multipart(env)
    obj = Datanet::Skel::Multipart.new(params)
    obj.files["neighbor"][:payload].should == "contents"
    obj.files["neighbor"][:filename].should == "picture.jpg"
    obj.files["neighbor2"].should be_nil
    obj.metadata.should_not be_nil
    obj.metadata.should be_an_instance_of String
  end

  it "parse multipart upload with file #{:message_meta_attr}" do
    env = Rack::MockRequest.env_for("/", multipart_fixture(:message_meta_attr))
    params = Rack::Utils::Multipart.parse_multipart(env)
    obj = Datanet::Skel::Multipart.new(params)
    obj.files["neighbor"][:payload].should == "contents"
    obj.files["neighbor"][:filename].should == "picture.jpg"
    obj.files["neighbor2"].should be_nil
    obj.metadata.should_not be_nil
    obj.metadata.should be_an_instance_of String
  end

  it "parse multipart upload with file #{:message_meta_attr_from_web}" do
    env = Rack::MockRequest.env_for("/", multipart_fixture(:message_meta_attr_from_web, "---------------------------2984324571314211228785232793"))
    params = Rack::Utils::Multipart.parse_multipart(env)
    obj = Datanet::Skel::Multipart.new(params)
    obj.files["upfile"][:payload].should == "contents"
    obj.files["upfile"][:filename].should == "plik.txt"
    obj.files["neighbor2"].should be_nil
    obj.metadata.should_not be_nil
    obj.metadata.should be_an_instance_of String
  end

  it "parse multipart upload with file #{:message_double_meta}" do
    env = Rack::MockRequest.env_for("/", multipart_fixture(:message_double_meta))
    caught = false
    begin
      params = Rack::Utils::Multipart.parse_multipart(env)
      obj = Datanet::Skel::Multipart.new(params)
    rescue Exception => e
      caught = true
      e.message.should == "Multiple specification of metadata"
    end
    caught.should == true
  end

  it "parse multipart upload with file #{:message_no_meta}" do
    env = Rack::MockRequest.env_for("/", multipart_fixture(:message_no_meta))
    caught = false
    begin
      params = Rack::Utils::Multipart.parse_multipart(env)
      obj = Datanet::Skel::Multipart.new(params)
    rescue Exception => e
      caught = true
      e.message.should == "Metadata not specified"
    end
    caught.should == true
  end

  it "parse multipart upload with file #{:message_no_files}" do
    env = Rack::MockRequest.env_for("/", multipart_fixture(:message_no_files))
    params = Rack::Utils::Multipart.parse_multipart(env)
    obj = Datanet::Skel::Multipart.new(params)
    obj.files.should be_nil
    obj.metadata.should_not be_nil
    obj.metadata.should eq ({ "attr1" => "value1", "attr2" => "value2" }.to_json)
  end

end
