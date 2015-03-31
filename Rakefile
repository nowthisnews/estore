require 'bundler'
require 'rspec/core/rake_task'

Bundler.setup

RSpec::Core::RakeTask.new(:spec)
task default: [:ci]

desc 'Run CI tasks'
task ci: [:spec]

begin
  require 'rubocop/rake_task'

  Rake::Task[:default].enhance [:rubocop]

  RuboCop::RakeTask.new do |task|
    task.options << '--display-cop-names'
  end
rescue LoadError
end

desc 'Update the protobuf messages definition'
task :proto do
  system("wget -O #{VENDORED_PROTO} #{PROTO_URL}")
  system("mkdir -p #{PROTO_DIR}")
  beefcake_bin = Bundler.bin_path.join('protoc-gen-beefcake').to_s
  if system("BEEFCAKE_NAMESPACE=Eventstore protoc --plugin=#{beefcake_bin} --beefcake_out lib/estore #{VENDORED_PROTO}")
    FileUtils.mv('lib/estore/ClientMessageDtos.pb.rb', 'lib/estore/messages.rb')
    system("sed -i '' 's/module Eventstore/class Eventstore/' lib/estore/messages.rb")
  end
end
