require 'spec_helper'
require 'unit/estore/connection_mock'

describe Estore::Commands::Append do
  subject(:append) do
    Estore::Commands::Append.new(connection, 'test-stream', events)
  end

  let(:events) do
    [{ type: 'something', data: 'something else' }, { type: 'stuff' }]
  end

  let(:connection) { Estore::ConnectionMock.new }
  let(:promise) { append.call }

  before do
    promise
  end

  it 'writes a message with the events to the connection buffer' do
    _uuid, _type, msg = connection.buffer.first

    expect(msg.events.size).to be(events.size)
  end

  it 'rejects the promise on errors' do
    append.handle(
      Estore::WriteEventsCompleted.new(
        result: Estore::OperationResult::AccessDenied
      )
    )

    expect { promise.sync }.to raise_error StandardError
  end
end
