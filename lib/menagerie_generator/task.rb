require_relative '../menagerie_generator'

module MenagerieGenerator
  class Task
    def initialize summary_path, time_series_path
      @summary_path = summary_path
      @summary = load_summary
      @time_series_path = time_series_path
    end


    private
      attr_reader :summary, :summary_path, :time_series_path

      def load_summary
        Summary.new (YAML.load_file summary_path)
      end
  end
end
