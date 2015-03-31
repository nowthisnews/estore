require 'spec_helper'
require 'timeout'
require 'json'

describe Estore do
  let(:es) { Estore.new('localhost', 1113) }
  subject { new_estore }
  let(:injector) { new_estore }

  def new_estore
    es = Estore.new('localhost', 1113)
    es.on_error { |error| Thread.main.raise(error) }
    es
  end

  it 'supports the PING command' do
    Timeout.timeout(1) do
      promise = es.ping
      result = promise.sync
      expect(result).to eql 'Pong'
    end
  end

  def inject_event(stream)
    event_type = 'TestEvent'
    data = JSON.generate(at: Time.now.to_i, foo: 'bar')
    event = injector.new_event(event_type, data)
    prom = injector.write_events(stream, event)
    prom.sync
  end

  it 'dumps the content of the outlet stream from the last checkpoint' do
    inject_events('outlet', 50)
    events = subject.read_stream_events_forward('outlet', 1, 20).sync
    expect(events).to be_kind_of(Estore::ReadStreamEventsCompleted)
    events.events.each do |event|
      expect(event).to be_kind_of(Estore::ResolvedIndexedEvent)
      JSON.parse(event.event.data)
    end
  end

  def inject_events_async(stream, target)
    Thread.new do
      begin
        inject_events(stream, target)
      rescue => error
        puts(error.inspect)
        puts(*error.backtrace)
        Thread.main.raise(error)
      end
    end
  end

  def inject_events(stream, target)
    target.times do |_i|
      inject_event(stream)
    end
  end

  it 'allows to make a live subscription' do
    stream = "subscription-test-#{SecureRandom.uuid}"
    received = 0

    sub = Estore::Subscription.new(subject, stream)
    sub.on_event { |_event| received += 1 }
    sub.on_error { |error| fail(error.inspect) }
    sub.start

    inject_events(stream, 50)

    Timeout.timeout(20) do
      loop do
        break if received >= 50
        sleep(0.1)
      end
    end
  end

  it 'allows to make a catch-up subscription' do
    stream = "catchup-test-#{SecureRandom.uuid}"
    received = 0
    mutex = Mutex.new

    expect(subject.ping.sync).to eql 'Pong'

    inject_events(stream, 10)

    sub = Estore::CatchUpSubscription.new(subject, stream, -1)
    sub.on_event { |_event| mutex.synchronize { received += 1 } }
    sub.on_error { |error| fail error.inspect }
    sub.start

    inject_events_async(stream, 10)

    Timeout.timeout(5) do
      loop do
        break if received >= 20
        sleep(0.5)
      end
    end
  end
end
