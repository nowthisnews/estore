require 'spec_helper'

describe Estore::EventRecord do
  subject do
    described_class.new(
      event_stream_id: 'my-stream',
      event_number: 123,
      event_id: '123-123-123-123',
      event_type: 'MyEvent',
      data_content_type: 5,
      metadata_content_type: 5,
      data: '{}',
    )
  end

  it { expect(subject.stream_name).to eql subject.event_stream_id }
  it { expect(subject.type).to eql subject.event_type }
end
