# encoding: utf-8
require 'simplecov'
require 'estore'

trap 'TTIN' do
  Thread.list.each do |thread|
    puts "Thread TID-#{thread.object_id.to_s(36)}"
    puts thread.backtrace.join("\n")
    puts "\n\n\n"
  end
end

class Integer
  # Just for readability
  def seconds
    self
  end
end

RSpec::Matchers.define :have do |expectation|
  match do |actual|
    if @timeout
      Timeout.timeout @timeout do
        loop do
          break if actual.to_a.size >= expectation
          sleep(0.1)
        end
      end
    end

    expect(actual.to_a.size).to @bigger ? be >= expectation : be(expectation)

    if @start
      actual.each_with_index do |wrapper, index|
        expect(wrapper.event.event_number).to be(index + @start)
      end
    end

    true
  end

  chain(:events) {}

  chain :before do |seconds|
    @timeout = seconds
  end

  chain :or_more do
    @bigger = true
  end

  chain :starting_at do |start|
    @start = start
  end
end
