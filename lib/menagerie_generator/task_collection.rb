require_relative '../menagerie_generator'

require 'yaml'

module MenagerieGenerator
  class TaskCollection
    def initialize summary_paths=[], time_series_paths=[]
    end

    def each_summary
    end

    def each_time_series
    end

    def last_summary
    end

    def first_summary
    end

    private
      attr_reader :summary_paths, :time_series_paths
  end
end
