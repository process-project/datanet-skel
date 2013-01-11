require 'logger'

class Logger
  def self.logger(logger = nil)
    if logger
      @@logger = logger
    else
      @@logger ||= Logger.new(STDOUT)
    end
  end
end