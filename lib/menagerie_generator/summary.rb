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
      @contents = translate_keys contents
    end

    def executable_name
      contents.fetch(:command).split(' ').first
    end

    private
      def method_missing m, *a, &b
        contents.fetch(m) { super }
      end

      def translate_keys h
        result = Hash.new
        h.each do |k,v|
          new_key = k.gsub /max_/, ''
          result[new_key.to_sym] = v
        end
        result
      end

      def contents
        @contents
      end
  end
end