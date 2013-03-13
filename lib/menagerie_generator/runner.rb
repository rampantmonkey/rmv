require_relative '../menagerie_generator'

require 'pathname'
require 'yaml'

module MenagerieGenerator
  class Runner
    attr_reader :source, :destination, :time_series, :summaries, :resources, :maximums

    def initialize argv
      process_arguments argv
    end

    def run
      find_files
      find_resources
      create_histograms
    end

    private
      def process_arguments args
        fail ::ArgumentError unless args.length > 1
        @source = Pathname.new args[0]
        @destination = Pathname.new args[1]
      end

      def find_files
        time_series = []
        summaries = []
        Pathname.glob(@source + "log-rule*") do |path|
          if path.to_s.match /.*summary/
            summaries << path
          else
            time_series << path
          end
        end
        @time_series = time_series
        @summaries = summaries
      end

      def find_resources
        header = time_series.first.open(&:readline).chomp
        header = header[1..-1]
        header = header.split /\s+/
        @resources = header.map {|h| h.gsub(/\(.*\)/, '')}
        @resources.map! {|r| translate_resource_name r}
        @resources.map! {|r| r.to_sym}
      end

      def translate_resource_name name
        name.gsub /clock/, 'time'
      end

      def create_histograms
        @maximums = find_maximums
        write_maximum_resources
      end

      def find_maximums
        max = Hash[ @resources.map {|r| [r,[]] }]
        @summaries.each do |s|
          summary = YAML.load_file s
          summary.each do |k,v|
            k = k.gsub /max_/, ''
            k = k.to_sym
            max[k].push v if max.has_key? k
          end
        end
        max
      end

      def write_maximum_resources
        @maximums.each do |m|
          path = @destination + m.first.to_s
          File.open(path, 'w:UTF-8') do |f|
            m.last.each { |line| f.puts line }
          end
        end
      end
  end
end
