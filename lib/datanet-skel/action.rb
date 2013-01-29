class Action

  def initialize container
    @container = container
  end

  def start
    begin
      execute
      @container.succeeded self
    rescue
      raise "Action failed"
    end
  end

  # will be rolled back only if it ends with success
  def execute
    raise "Method not implemented yet"
  end

  # rolls back succeeded action
  def rollback
  end

end