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

  RSpec::Matchers.define :start_from do |start|
    match do |events|
      events.each_with_index do |event, index|
        expect(parse_data(event)).to eql('id' => index + start)
      end
    end
  end

  it 'reads an interval of events from stream' do
    read = session.read(stream_with(30), 15, 15).sync

    expect(read.events.size).to be(15)
    expect(read.events).to start_from(15)
  end

  it 'allows to make a live subscription' do
    stream = random_stream
    received = []

    stream_with(20, stream)

    sub = session.subscription(stream)
    sub.on_error { |error| raise error.inspect }
    sub.on_event { |event| received << event }
    sub.start

    stream_with(50, stream)

    Timeout.timeout(5) do
      loop do
        break if received.size >= 50
        sleep(0.1)
      end
    end

    expect(received.size).to be(50)
    expect(received).to start_from(20)
  end

  it 'allows to make a catchup subscription' do
    stream = random_stream
    received = []

    stream_with(50, stream)

    sub = session.subscription(stream, catch_up_from: 20)
    sub.on_error { |error| raise error.inspect }
    sub.on_event { |event| received << event }
    sub.start

    Thread.new do
      50.times do
        stream_with(2, stream)
      end
    end

    Timeout.timeout(5) do
      loop do
        break if received.size >= 130
        sleep(0.1)
      end
    end

    expect(received.size).to be(130)
    expect(received).to start_from(20)
  end
end
