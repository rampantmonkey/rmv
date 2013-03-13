require_relative '../menagerie_generator'

module MenagerieGenerator
  class Runner
    attr_reader :source, :destination, :time_series, :summaries

    def initialize argv
      process_arguments argv
    end

    def run
      find_files
    end

    private
      def process_arguments args
        fail ::ArgumentError unless args.length > 1
        @source = Pathname.new args[0]
        @destination = Pathname.new args[1]
      end

      def find_files
        time_series = []
        summaries = []
        Pathname.glob(@source + "log-rule*") do |path|
          if path.to_s.match /.*summary/
            summaries << path
          else
            time_series << path
          end
        end
        @time_series = time_series
        @summaries = summaries
      end
  end
end
