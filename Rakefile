require 'bundler'
require 'rspec/core/rake_task'

Bundler.setup

RSpec::Core::RakeTask.new(:spec)
task default: [:spec]

task :test # TODO: use rspec tests when real event store is available in unit tests on jenkins

# https://github.com/EventStore/EventStore/blob/release-v3.9.2/src/Protos/ClientAPI/ClientMessageDtos.proto
# https://github.com/EventStore/EventStore/blob/release-v4.0.0/src/Protos/ClientAPI/ClientMessageDtos.proto

VENDORED_PROTO = 'vendor/proto/ClientMessageDtos.proto'
PROTO_URL = 'https://raw.githubusercontent.com/EventStore/EventStore/'\
            'release-v3.9.2/src/Protos/ClientAPI/ClientMessageDtos.proto'

desc 'Update the protobuf messages definition'
task :proto do
  system("wget -O #{VENDORED_PROTO} #{PROTO_URL}")

  beefcake = Bundler.bin_path.join('protoc-gen-beefcake').to_s

  if system("BEEFCAKE_NAMESPACE=Estore protoc --plugin=#{beefcake} "\
      "--beefcake_out lib/estore #{VENDORED_PROTO}")
    FileUtils.mv('lib/estore/ClientMessageDtos.pb.rb', 'lib/estore/messages.rb')
    system("sed -i '' 's/module Eventstore/class Eventstore/' "\
        "lib/estore/messages.rb")
  end
end
