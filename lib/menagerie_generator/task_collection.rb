require_relative '../menagerie_generator'

require 'yaml'

module MenagerieGenerator
  class TaskCollection
    def initialize summary_paths=[], time_series_paths=[]
      @tasks = summary_paths.zip(time_series_paths).map { |sp, tp| Task.new(sp,tp) }
    end

    def each &block
      tasks.send :each, &block
    end

    def last
      tasks.last
    end

    def first
      tasks.first
    end

    private
      attr_reader :tasks
  end
end