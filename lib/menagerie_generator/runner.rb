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
        write_maximum_values {|a, b| scale_maximum a, b}
        build_histograms
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

      def scale_maximum key, value
        value /= 1024 if key.match /byte/
        value
      end

      def write_maximum_values
        @maximums.each do |m|
          path = @destination + m.first.to_s
          File.open(path, 'w:UTF-8') do |f|
            m.last.each do |line|
              line = yield( m.first, line) if block_given?
              f.puts line
            end
          end
        end
      end

      def build_histograms
        @resources.each do |r|
          gnuplot {|io| io.puts histogram_format(resource: r, data_path: @destination+r.to_s)}
        end
      end

      def gnuplot
        output = nil
        begin
          IO::popen "gnuplot", "w+" do |io|
            yield io
            io.close_write
            output = io.read
          end
        rescue ENOENT => e
          puts "gnuplot not installed"
        end
        output
      end

      def histogram_format(width: 600, height: 600, resource: "", data_path: "/tmp")
        %Q{set terminal png size #{width},#{height}
        set bmargin 4
        set style line 1
        unset key

        set ylabel "Frequency"
        set output "#{@destination + resource.to_s}_hist.png"
        binwidth=1
        set boxwidth binwidth*0.9
        set style fill solid 0.5
        bin(x,width)=width*floor(x/width)
        set yrange [0:*]
        set xlabel "#{resource.to_s}"
        plot "#{data_path.to_s}" using (bin(\$1,binwidth)):(1.0) smooth freq with boxes
        }
      end
  end
end
