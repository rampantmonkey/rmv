require_relative '../menagerie_generator'

require 'optparse'
require 'pathname'

module MenagerieGenerator
  class Options

    def initialize argv
      @config = {source: nil,
                 debug: false,
                 destination: nil,
                 name: "unnamed",
                 workspace: Pathname.new("/tmp/menagerie")}
      parse argv
      mandatory = [:source, :destination]
      missing = mandatory.select { |param| config[param].nil? }
      unless missing.empty?
        STDERR.puts "Missing options: #{missing.join(', ')}"
        exit -1
      end
    end

    def method_missing m, *a, &b
      config.fetch(m){ super}
    end

    def parse argv
      OptionParser.new do |opts|
        opts.banner = "Usage:    menagerie [options] "
        opts.on("-D", "--debug", "Keep intermediate files and produce more verbose output") do
          config[:debug] = true
        end
        opts.on("-d", "--destination path", String, "Directory in which to place the output") do |d|
          config[:destination] = Pathname.new d
        end
        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        opts.on("-n", "--name name", String, "Set the name of the workflow") do |n|
          config[:name] = n
        end
        opts.on("-s", "--source path", String, "Directory to the log files for visualizing") do |s|
          puts s
          config[:source] = Pathname.new s
        end
        opts.on("-w", "--workspace path", String, "Directory for storing temporary files. Default: /tmp/menagerie") do
          config[:workspace] = Pathname.new w
        end

        begin
          argv = ["-h"] if argv.empty?
          opts.parse! argv
        rescue OptionParser::ParseError => e
          STDERR.puts e.message, "\n", opts
          exit(-1)
        end
      end
    end

    private
      attr_accessor :config
  end
end

