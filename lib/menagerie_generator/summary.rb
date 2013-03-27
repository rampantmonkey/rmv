require_relative '../menagerie_generator'

require 'yaml'

module MenagerieGenerator
  class Summary
    class << self
      def from_file path
         Summary.new (YAML.load_file path)
      end

    end

    def initialize contents
      @contents = contents
    end

    private
      def method_missing m, *a, &b
        contents.fetch(m.to_s) { super }
      end

      def contents
        @contents
      end
  end
end
