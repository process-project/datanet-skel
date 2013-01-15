require 'settingslogic'

class TestSettings < Settingslogic

  class << self
    def config_file
      test_settings = config_file_path('test_config.yml')
      File.exists?(test_settings) ? test_settings : config_file_path('default_test_config.yml')
    end

    private

    def config_dir
      File.join(File.dirname(__FILE__), '..', 'config')
    end

    def config_file_path(file_name)
      File.join(config_dir, file_name)
    end
  end

  source config_file
  load!
end