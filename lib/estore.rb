require 'securerandom'

# The Eventstore class is responsible for maintaining a full-duplex connection
# between the client and the Event Store server.
# EventStore is thread-safe, and it is recommended that only one instance per application is created.
#
# All operations are handled fully asynchronously, returning a promise.
# If you need to execute synchronously, simply call .sync on the returned promise.
#
# To get maximum performance from the connection, it is recommended that it be used asynchronously.
class Eventstore
  attr_reader :host, :port, :connection, :context, :error_handler
  def initialize(host, port = 2113)
    @host = host
    @port = port
    @context = ConnectionContext.new
    @connection = Connection.new(host, port, context)
  end

  def on_error(error = nil, &block)
    context.on_error(error, &block)
  end

  def close
    connection.close
  end

  def ping
    command('Ping')
  end

  def new_event(event_type, data, content_type: 'json', uuid: nil)
    uuid ||= SecureRandom.uuid
    content_type_code = { 'json' => 1 }.fetch(content_type, 0)
    NewEvent.new(
      event_id: Package.encode_uuid(uuid),
      event_type: event_type,
      data: data,
      data_content_type: content_type_code,
      metadata_content_type: 1
    )
  end

  def write_events(stream, events)
    events = Array(events)
    msg = WriteEvents.new(
      event_stream_id: stream,
      expected_version: -2,
      events: events,
      require_master: true
    )
    command('WriteEvents', msg)
  end

  def read_stream_events_forward(stream, start, max)
    msg = ReadStreamEvents.new(
      event_stream_id: stream,
      from_event_number: start,
      max_count: max,
      resolve_link_tos: true,
      require_master: false
    )
    command('ReadStreamEventsForward', msg)
  end

  def subscribe_to_stream(handler, stream, resolve_link_tos = false)
    msg = SubscribeToStream.new(event_stream_id: stream, resolve_link_tos: resolve_link_tos)
    command('SubscribeToStream', msg, handler)
  end

  def unsubscribe_from_stream(subscription_uuid)
    msg = UnsubscribeFromStream.new
    command('UnsubscribeFromStream', msg, uuid: subscription_uuid)
  end

  private

  def command(*args)
    connection.send_command(*args)
  end
end

require_relative 'estore/errors'
require_relative 'estore/package'
require_relative 'estore/messages'
require_relative 'estore/message_extensions'
require_relative 'estore/connection_context'
require_relative 'estore/connection'
require_relative 'estore/connection/buffer'
require_relative 'estore/connection/commands'
require_relative 'estore/subscription'
require_relative 'estore/catchup_subscription'
