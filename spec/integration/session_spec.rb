require 'spec_helper'
require 'securerandom'
require 'json'

describe Estore::Session do
  subject(:session) { Estore::Session.new('127.0.0.1', 1113) }

  before do
    @id = -1
  end

  def data
    @id += 1
    { 'id' => @id }
  end

  def parse_data(wrapper)
    JSON.parse(wrapper.event.data)
  end

  def event
    {
      type: 'TestEvent',
      data: data.to_json
    }
  end

  def events(n)
    (1..n).map { event }
  end

  def random_stream
    "test-#{SecureRandom.uuid}"
  end

  def stream_with(count, stream = nil)
    stream ||= random_stream
    session.append(stream, events(count)).sync
    stream
  end

  it 'pings the Event Store' do
    Timeout.timeout(5) { session.ping.sync }
  end

  it 'reads all the events from a stream' do
    stream = session.read(stream_with(200)).sync

    expect(stream).to have(200).events.starting_at(0)
  end

  it 'reads all the events forward from a stream' do
    stream = session.read(stream_with(100), from: 20).sync

    expect(stream).to have(80).events.starting_at(20)
  end

  it 'reads a batch of events from a stream' do
    stream = session.read(stream_with(30), from: 10, limit: 15).sync

    expect(stream).to have(15).events.starting_at(10)
  end

  it 'reads no events if the stream does not exist' do
    stream = session.read('doesnotexist').sync

    expect(stream).to have(0).events
  end

  it 'allows to make a live subscription' do
    stream = random_stream
    received = []

    stream_with(20, stream)

    sub = session.subscription(stream)
    sub.on_event { |event| received << event }
    sub.start

    stream_with(50, stream)

    expect(received).to have(50).events.starting_at(20).before(5.seconds)
  end

  it 'allows to make a catchup subscription' do
    stream = random_stream
    received = []

    stream_with(2100, stream)

    sub = session.subscription(stream, from: 30)

    sub.on_event do |event|
      # Events received during processing should be
      # received later too
      sleep 1 if received.size < 1
      received << event
      puts "Receiving... #{received.size}"
    end

    Thread.new do
      30.times do
        stream_with(2, stream)
      end
    end

    sub.start

    expect(received).to have(2130).events.starting_at(30).before(20.seconds)
  end

  it 'allows to make a catchup subscription to a non-existing stream' do
    stream = random_stream
    received = []

    sub = session.subscription(stream, from: 0)

    sub.on_event do |event|
      # Events received during processing should be
      # received later too
      sleep 1 if received.size < 1
      received << event
      puts "Receiving... #{received.size}"
    end

    sub.start

    Thread.new do
      30.times do
        stream_with(2, stream)
      end
    end

    expect(received).to have(60).events.starting_at(0).before(20.seconds)
  end
end
