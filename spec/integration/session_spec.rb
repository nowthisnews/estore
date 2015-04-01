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

  def populate(count, stream = nil)
    stream ||= random_stream
    session.append(stream, events(count)).sync
    stream
  end

  it 'reads events from a stream' do
    stream = populate(20)
    read = session.read(stream, 0, 20).sync

    expect(read.events.size).to be(20)

    read.events.each_with_index do |event, index|
      expect(parse_data(event)).to eql('id' => index)
    end
  end

  it 'allows to make a live subscription' do
    stream = random_stream
    received = 0

    sub = session.subscription(stream)
    sub.on_error { |error| raise error.inspect }

    sub.on_event do |event|
      expect(parse_data(event)).to eql('id' => received)
      received += 1
    end

    sub.start

    populate(50, stream)

    Timeout.timeout(5) do
      loop do
        break if received >= 50
        sleep(0.1)
      end
    end
  end

  it 'allows to make a catchup subscription' do
    stream = random_stream
    received = 0

    populate(50, stream)

    sub = session.subscription(stream, catch_up_from: 20)
    sub.on_error { |error| raise error.inspect }

    sub.on_event do |event|
      expect(parse_data(event)).to eql('id' => received + 20)
      received += 1
    end

    sub.start

    Thread.new do
      50.times do
        populate(2, stream)
      end
    end

    Timeout.timeout(5) do
      loop do
        break if received >= 130
        sleep(0.1)
      end
    end
  end
end
