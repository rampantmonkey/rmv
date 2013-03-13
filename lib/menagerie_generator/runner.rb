require_relative '../menagerie_generator'

module MenagerieGenerator
  class Runner
    attr_reader :source, :destination

    def initialize argv
      process_arguments argv
    end

    def run
    end

    private
      def process_arguments args
        fail ::ArgumentError unless args.length > 1
        @source = args[0]
        @destination = args[1]
      end
  end
end
