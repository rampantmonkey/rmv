require_relative '../menagerie_generator'

module MenagerieGenerator
  class Runner
    attr_reader :source, :destination

    def initialize argv
      @source = argv[0]
      @destination = argv[1]
    end
  end
end
