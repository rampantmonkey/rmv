require_relative '../menagerie_generator'

module MenagerieGenerator
  class Task
    def initialize summary_path, time_series_path
      @summary_path = summary_path
      @summary = load_summary
      @time_series_path = time_series_path
    end

    def rule_id
      summary_path.to_s.match(/log-rule-(\d+)-summary/)[1]
    end

    def executable_name
      summary.executable_name
    end

    def max resource
      summary.send resource.to_sym
    end

    private
      attr_reader :summary, :summary_path, :time_series_path

      def load_summary
        Summary.new (YAML.load_file summary_path)
      end
  end
end
