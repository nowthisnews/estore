module Estore
  module Commands
    module ReadStreamForward
      def read(stream, from, limit)
        msg = ReadStreamEvents.new(
          event_stream_id: stream,
          from_event_number: from,
          max_count: limit,
          resolve_link_tos: true,
          require_master: false
        )

        write('ReadStreamEventsForward', msg)
      end

      def error(response)
        case response.result
        when ReadStreamEventsCompleted::ReadStreamResult::AccessDenied
          'Access denied (stream does not exist?)'
        when ReadStreamEventsCompleted::ReadStreamResult::Error
          response.error ? response.error : 'No message given'
        else
          false
        end
      end
    end
  end
end
