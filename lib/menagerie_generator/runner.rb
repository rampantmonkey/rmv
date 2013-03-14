require_relative '../menagerie_generator'

require 'pathname'
require 'yaml'
require 'open3'

module MenagerieGenerator
  class Runner
    attr_reader :source, :destination, :time_series, :summaries, :resources, :maximums, :workspace

    def initialize argv
      process_arguments argv
    end

    def run
      find_files
      find_resources
      create_histograms
      make_index [[600,600],[250,250]]
    end

    private
      def process_arguments args
        fail ::ArgumentError unless args.length > 1
        @source = Pathname.new args[0]
        @workspace = Pathname.new "/tmp/menagerie-generator/"
        @workspace.mkpath
        @destination = Pathname.new args[1]
        @destination.mkpath unless @destination.exist?
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
        build_histograms [[600,600],[250,250]]
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
          path = workspace + m.first.to_s
          File.open(path, 'w:UTF-8') do |f|
            m.last.each do |line|
              line = yield( m.first, line) if block_given?
              f.puts line
            end
          end
        end
      end

      def make_index sizes=[[600,600]]
        path = destination + "index.html"
        output = <<-INDEX
        <!doctype html>
        <meta charset="UTF-8">
        <meta name="viewport" content="initial-scale=1.0, width=device-width" />
        <link rel="stylesheet" type="text/css" media="screen, projection" href="css/screen.css" />
        INDEX
        sizes.sort_by! {|s| s.first}
        @resources.each do |r|
          output << %Q{<a href="#{r.to_s}_#{sizes.last.first}x#{sizes.last.last}_hist.png"><img src="#{r.to_s}_#{sizes.first.first}x#{sizes.first.last}_hist.png" /></a>\n}
        end
        path.open("w:UTF-8") { |f| f.puts output }
      end

      def build_histograms sizes=[[600,600]]
        sizes.each do |s|
          width = s.first
          height = s.last
          @resources.each do |r|
            gnuplot {|io| io.puts histogram_format(width: width, height: height, resource: r, data_path: workspace+r.to_s)}
          end
        end
      end

      def gnuplot
        output = nil
        begin
          Open3::popen3 "gnuplot" do |i, o, e, t|
            yield i
            i.close_write
          end
        rescue Errno::ENOENT => e
          puts "gnuplot not installed"
        end
        output
      end

      def histogram_format(width: 600, height: 600, resource: "", data_path: "/tmp")
        max = scale_maximum resource.to_s, @maximums[resource].max
        binwidth = 1
        binwidth = max/40 unless max <= 40
        %Q{set terminal png size #{width},#{height}
        set bmargin 4
        set style line 1
        unset key

        set ylabel "Frequency"
        set output "#{@destination + resource.to_s}_#{width}x#{height}_hist.png"
        binwidth=#{binwidth}
        set boxwidth binwidth*0.9
        set style fill solid 0.5
        bin(x,width)=width*floor(x/width)
        set yrange [0:*]
        set xrange [0:*]
        set xtics right rotate by -45
        set xlabel "#{resource.to_s}" offset 0,-2 character
        set bmargin 7
        plot "#{data_path.to_s}" using (bin(\$1,binwidth)):(1.0) smooth freq with boxes
        }
      end
  end
end
