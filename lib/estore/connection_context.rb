require 'promise'

module Estore
  # Registry storing handlers for the pending commands
  class ConnectionContext
    def initialize
      @mutex = Mutex.new
      @commands = {}
    end

    def register(command)
      unless command.finished?
        @mutex.synchronize do
          @commands[command.uuid] = command
        end
      end
    end

    def dispatch(uuid, message)
      command = @commands[uuid]

      if command
        command.handle message

        if command.finished?
          @mutex.synchronize do
            @commands.delete(uuid)
          end
        end
      end
    end

    def rejected_command(uuid, error)
      prom = nil

      mutex.synchronize do
        prom = requests.delete(uuid)
      end

      prom.reject(error) if prom
    end

    def trigger(uuid, method, *args)
      target = mutex.synchronize { targets[uuid] }
      return if target.nil?
      target.__send__(method, *args)
    end

    def on_error(error = nil, &block)
      if block
        @error_handler = block
      else
        @error_handler.call(error) if @error_handler
      end
    end

    private

    def promise(uuid, target = nil)
      prom = Promise.new(uuid)
      mutex.synchronize do
        requests[uuid] = prom
        targets[uuid] = target
      end
      prom
    end
  end
end
