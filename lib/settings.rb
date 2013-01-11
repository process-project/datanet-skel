require 'settingslogic'

class Settings < Settingslogic
  settings_file = File.join(File.dirname(__FILE__), '..', 'config', 'config.yml')
  source settings_file
  load!
end