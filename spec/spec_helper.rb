# encoding: utf-8
if RUBY_ENGINE == 'rbx'
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'estore'

trap 'TTIN' do
  Thread.list.each do |thread|
    puts "Thread TID-#{thread.object_id.to_s(36)}"
    puts thread.backtrace.join("\n")
    puts "\n\n\n"
  end
end
