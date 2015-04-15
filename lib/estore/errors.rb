module Estore
  CannotConnectError = Class.new(StandardError)
  DisconnectionError = Class.new(StandardError)
  WriteEventsError = Class.new(StandardError)
  ReadEventsError = Class.new(StandardError)
end
