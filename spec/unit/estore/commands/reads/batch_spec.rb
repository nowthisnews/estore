require 'spec_helper'
require 'unit/estore/connection_mock'

describe Estore::Commands::ReadBatch do
  subject(:read) do
    Estore::Commands::ReadBatch.new(connection, 'test-stream', 5, 10)
  end

  let(:message) { Estore::ReadStreamEventsCompleted }
  let(:connection) { Estore::ConnectionMock.new }
  let(:promise) { read.call }

  def result(type)
    message.new(
      result: message::ReadStreamResult.const_get(type)
    )
  end

  before do
    promise
  end

  it 'rejects the promise on errors' do
    read.handle(result(:Error))

    expect { promise.sync }.to raise_error StandardError, 'No message given (stream \'test-stream\' does not exist?)'
  end

  it 'rejects the promise when access is denied' do
    read.handle(result(:AccessDenied))

    expect { promise.sync }.to raise_error StandardError
  end
end
