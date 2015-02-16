require 'promise'

class Eventstore
  class Promise < ::Promise
    def wait
      t = Thread.current
      resume = proc { t.wakeup }
      self.then(resume, resume)
      sleep
    end
  end

  class ConnectionContext
    attr_reader :mutex,  :requests, :targets
    def initialize
      @mutex = Mutex.new
      @requests = {}
      @targets = {}
    end

    def register_command(uuid, command, target=nil)
      #p fn: "register_command", uuid: uuid, command: command
      case command
      when "Ping" then promise(uuid)
      when "ReadStreamEventsForward" then promise(uuid)
      when "SubscribeToStream" then promise(uuid, target)
      when "WriteEvents" then promise(uuid)
      when "HeartbeatResponseCommand" then :nothing_to_do
      else fail("Unknown command #{command}")
      end
    end

    def fulfilled_command(uuid, value)
      prom = nil
      mutex.synchronize {
        prom = requests.delete(uuid)
      }
      #p fn: "fulfilled_command", uuid: uuid, prom: prom, requests: requests
      prom.fulfill(value) if prom
    end

    def rejected_command(uuid, error)
      prom = nil
      mutex.synchronize {
        prom = requests.delete(uuid)
      }
      #p fn: "fulfilled_command", uuid: uuid, prom: prom, requests: requests
      prom.reject(error) if prom
    end

    def trigger(uuid, method, args)
      target = mutex.synchronize { targets[uuid] }
      return if target.nil?
      target.__send__(method, *args)
    end

    def on_error(error=nil, &block)
      if block
        @error_handler = block
      else
        @error_handler.call(error) if @error_handler
      end
    end

    private

    def promise(uuid, target=nil)
      prom = Promise.new
      mutex.synchronize {
        requests[uuid] = prom
        targets[uuid] = target
      }
      prom
    end

  end
end
