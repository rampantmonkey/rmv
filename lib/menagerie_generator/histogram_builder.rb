require_relative '../menagerie_generator'

module MenagerieGenerator
  class HistogramBuilder
    def initialize resources, summaries, workspace, destination
      @resources = resources
      @summaries = summaries
      @workspace = workspace
      @destination = destination
    end

    def build sizes=[[600,600]], output=""
    end
    def find_groups
    end
    private
      attr_reader :resources, :summaries, :workspace, :destination
  end
end
