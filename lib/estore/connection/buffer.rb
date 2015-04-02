module Estore
  class Connection
    # Buffer receives data from the TCP connection, and parses the binary
    # packages.
    # Parsed packages are given back to the given handler as they are decoded.
    class Buffer

      def initialize(&block)
        @mutex = Mutex.new
        @buffer = ''.force_encoding('BINARY')
        @handler = block
      end

      def <<(bytes)
        bytes = bytes.force_encoding('BINARY') if
          bytes.respond_to? :force_encoding

        @mutex.synchronize do
          @buffer << bytes
        end

        consume_packages
      end

      def consume_packages
        while (pkg = read_package)
          handle(pkg)
          discard_bytes(pkg)
        end
      end

      def read_package
        return nil if @buffer.length < 4
        package_length = @buffer[0...4].unpack('l<').first
        bytes = @buffer[4...(4 + package_length)].dup
        bytes if bytes.bytesize >= package_length
      end

      def discard_bytes(pkg)
        @mutex.synchronize do
          @buffer = @buffer[(4 + pkg.bytesize)..-1]
        end
      end

      def handle(pkg)
        code, flags, uuid_bytes, message = parse(pkg)
        command = Estore::Connection.command_name(code)
        @handler.call(command, message, Package.parse_uuid(uuid_bytes), flags)
      end

      def parse(pkg)
        [
          pkg[0].unpack('C').first,
          pkg[1].unpack('C').first,
          pkg[2...(2 + 16)],
          pkg[18..-1]
        ]
      end
    end
  end
end
