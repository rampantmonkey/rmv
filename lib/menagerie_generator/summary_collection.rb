require_relative '../menagerie_generator'

require 'yaml'

module MenagerieGenerator
  class SummaryCollection
    def initialize paths
      @paths = Array(paths)
    end

    def each
      paths.each do |p|
        yield (Summary.from_file p)
      end
    end

    def last
      paths.last
    end

    def first
      paths.first
    end

    private
      attr_reader :paths
  end
end
