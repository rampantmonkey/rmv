require_relative '../menagerie_generator'

module MenagerieGenerator
  class HistogramBuilder
    def initialize resources, summaries, workspace, destination
      @resources = resources
      @summaries = summaries
      @workspace = workspace
      @destination = destination
    end

    private
      attr_reader :resources, :summaries, :workspace, :destination
  end
end
