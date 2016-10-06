require 'spec_helper'

describe Estore::Package do
  subject(:package) { Estore::Package }

  it 'rejects the promise on errors' do
    expect { package.decode('boom', 'boom') }.to raise_error StandardError
  end
end
