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
    end

    def parse argv
      OptionParser.new do |opts|
        opts.banner = "Usage:    menagerie [options] "
        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
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

