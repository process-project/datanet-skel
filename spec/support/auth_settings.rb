require 'settingslogic'

class AuthSettings < Settingslogic

  class << self
    def config_file
      File.join(config_dir, 'auth_config.yml')
    end

    private

    def config_dir
      File.join(File.dirname(__FILE__), '..', 'config')
    end
  end

  source config_file
  load!
end