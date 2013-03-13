require_relative '../menagerie_generator'

module MenagerieGenerator
  class Runner
    attr_reader :source, :destination

    def initialize argv
      fail ::ArgumentError unless argv.length > 1
      @source = argv[0]
      @destination = argv[1]
    end
  end
end
