module Estore
  module Commands
    class Promise < ::Promise
      attr_reader :correlation_id

      def initialize(correlation_id)
        super()
        @correlation_id = correlation_id
      end

      def wait
        t = Thread.current
        resume = proc { t.wakeup }
        self.then(resume, resume)
        sleep
      end
    end
  end
end
