module Estore
  class ConnectionMock
    attr_reader :buffer, :registry

    def initialize
      @buffer = []
      @registry = {}
    end

    def write(uuid, type, msg)
      @buffer << [uuid, type, msg]
    end

    def register(command)
      @registry[command.uuid] = command
    end

    def remove(command)
      @registry.delete(command.uuid)
    end
  end
end
