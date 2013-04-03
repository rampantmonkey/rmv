require_relative '../menagerie_generator'

require 'yaml'

module MenagerieGenerator
  class TaskCollection
    def initialize summary_paths=[], time_series_paths=[]
      @tasks = summary_paths.zip(time_series_paths).map { |sp, tp| Task.new(sp,tp) }
    end

    def each
    end

    def last
    end

    def first
    end

    private
      attr_reader :tasks
  end
end
