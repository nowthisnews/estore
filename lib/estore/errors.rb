module Estore
  class WriteEventsError < StandardError
    attr_reader :result

    def initialize(result = nil)
      super(result&.message || 'Write events error')
      @result = result
    end
  end

  CannotConnectError = Class.new(StandardError)
  DisconnectionError = Class.new(StandardError)
  ReadEventsError = Class.new(StandardError)
end
