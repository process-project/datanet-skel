$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'api'))

# $stdout = StringIO.new

require 'rubygems'
require 'bundler'
Bundler.setup :default, :test

require 'pry'
require 'rack/test'

require 'grape'
require 'json'
require 'json-schema'

require 'datanet-skel'

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
  require file
end

RSpec.configure do |config|
  #http://stackoverflow.com/a/7853245/1535165
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end


def empty_models_dir
  File.join(File.dirname(__FILE__), 'resources')
end

def models_dir
  File.join(File.dirname(__FILE__), 'resources', 'models')
end

def model_path(model_name)
  File.join(models_dir, "#{model_name}.json")
end

def auth_dir
  File.join(File.dirname(__FILE__), 'resources', 'auth')
end