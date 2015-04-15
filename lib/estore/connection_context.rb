require 'promise'

module Estore
  # Registry storing handlers for the pending commands
  class ConnectionContext
    def initialize
      @mutex = Mutex.new
      @commands = {}
    end

    def register(command)
      @mutex.synchronize do
        @commands[command.uuid] = command
      end
    end

    def remove(command)
      @mutex.synchronize do
        @commands.delete(command.uuid)
      end
    end

    def dispatch(uuid, message)
      command = @commands[uuid]
      command.handle(message) if command
    rescue => error
      command.reject! error
      remove(command)

      puts "[DISPATCH] #{error.message}"
      puts error.backtrace
    end

    def empty?
      @commands.empty?
    end

    def on_error(error)
      # TODO: Error handling
      @mutex.synchronize do
        @commands.each { |_uuid, command| command.reject! error }
        @commands = {}
      end
    end
  end
end
