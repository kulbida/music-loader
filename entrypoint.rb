require "yajl"

require_relative "operations"
require_relative "serializers"
require_relative "utils"


# Validates each operation from the file for proper formatting
operations = Yajl::Parser.parse(File.read(ARGV[0])).map do |op|
  Kernel.const_get(op['optype']).new(op)
end.select(&:valid?)

processor = Processor.new(operations)

# Central data store & management controls
collector = Collector.new(processor, [User, Song, Playlist])

# Loading data as a stream, we can also use TCPSocket, etc.
data = Yajl::Parser.parse(STDIN)

# Data integrity checks & configuration
data.keys.lazy.each do |key|
  data[key].each_slice(500) do |bucket|
    bucket.each do |slice|
      if factory = ObjectFacade.get(key, collector.facades)
        collector.storage[factory.selector].push(factory.new(slice))
      else
        STDERR.puts("Unprocessable collection type '#{key}'.")
      end
    end
  end
end

# Processing & output
STDOUT.puts(collector.run!.to_json)
