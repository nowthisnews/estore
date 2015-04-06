require 'spec_helper'

describe Estore::ConnectionContext do
  subject(:context) { Estore::ConnectionContext.new }

  let(:bad_command) do
    BadCommand = Class.new do
      attr_reader :error

      def uuid
        'test'
      end

      def reject!(error)
        @error = error
      end

      def handle(_msg)
        boom
      end
    end

    BadCommand.new
  end

  before do
    context.register(bad_command)
  end

  it 'rejects a command when exceptions happen inside the command' do
    context.dispatch('test', 'something')

    expect(bad_command.error).to be_instance_of(NameError)
  end

  it 'removes all commands when exceptions happen inside the command' do
    context.dispatch('test', 'something')

    expect(context.empty?).to be_truthy
  end

  it 'rejects a command when exceptions happen in the connection' do
    context.on_error(StandardError.new('this is an error'))

    expect(bad_command.error).to be_instance_of(StandardError)
  end

  it 'removes all commands when exceptions happen in the connection' do
    context.on_error('this is an error')

    expect(context.empty?).to be_truthy
  end
end
