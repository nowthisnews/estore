module Estore
  module Commands
    class LiveSubscription
      include Command
      include Commands::Subscription

      handle StreamEventAppeared => :event_appeared,
             SubscriptionConfirmation => :ignore

      def event_appeared(response)
        enqueue response.event
      end
    end
  end
end
