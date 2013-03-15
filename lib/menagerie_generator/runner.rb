require_relative '../menagerie_generator'

require 'pathname'
require 'yaml'
require 'open3'

module MenagerieGenerator
  class Runner
    attr_reader :source, :destination, :time_series, :summaries, :resources, :maximums, :workspace, :name, :units

    def initialize argv
      process_arguments argv
    end

    def run
      find_files
      find_resources
      create_histograms
      make_combined_time_series
      make_index [[600,600],[250,250]]
      copy_static_files
    end

    private
      def find_start_time
        summary =  YAML.load_file summaries.first
        lowest = summary["start"]
        summary = YAML.load_file summaries.last
        highest = summary["start"]
        lowest < highest ? lowest : highest
      end

      def make_combined_time_series
        usage = find_aggregate_usage
        write_usage usage
        plot_time_series_summaries [[1250,500]]
      end

      def write_usage usage
        usage.each do |u|
          path = workspace + "aggregate_#{u.first.to_s}"
          output = []
          u.last.each {|k,v| output << "#{k}\t#{v}"}
          output.sort_by! do |a|
            a = a.split(/\t/)
            a[0].to_i
          end
          path.open("w:UTF-8"){|f| f.puts output}
        end
      end

      def plot_time_series_summaries sizes
        sizes.each do |s|
          width = s.first
          height = s.last
          @resources.each do |r|
            gnuplot {|io| io.puts time_series_format(width: width, height: height, resource: r, data_path: workspace+"aggregate_#{r.to_s}")}
          end
        end
      end

      def time_series_format(width: 1250, height: 500, resource: "", data_path: "/tmp")
        unit = @units[@resources.index(resource)]
        unit = " (#{unit})" unless unit == ""
        %Q{set terminal png transparent size #{width},#{height}
        set bmargin 4
        unset key
        set xlabel "Time (seconds)" offset 0,-2 character
        set ylabel "#{resource.to_s}#{unit}" offset 0,-2 character
        set output "#{@destination + resource.to_s}_#{width}x#{height}_aggregate.png"
        set yrange [0:*]
        set xrange [0:*]
        set xtics right rotate by -45
        set bmargin 7
        plot "#{data_path.to_s}" using 1:2 w lines lw 5 lc rgb"#465510"
        plot "#{data_path.to_s}" using (bin(\$1,binwidth)):(1.0) smooth freq w boxes lc rgb"#5aabbc"
        }
      end

      def find_aggregate_usage
        start = find_start_time.to_i
        aggregate_usage = {}
        @resources.each {|r| aggregate_usage[r] = Hash.new 0}
        @time_series.each do |s|
          lines = s.open.each
          lines.each do |l|
            unless l.match /^#/
              data = l.split /\s+/
              adjusted_start = data[0].to_i - start
              @resources.each_with_index do |r, i|
                aggregate_usage[r][adjusted_start] += data[i].to_i unless i == 0
              end
            end
          end
        end
        aggregate_usage
      end

      def process_arguments args
        fail ::ArgumentError unless args.length > 1
        @source = Pathname.new args[0]
        @workspace = Pathname.new "/tmp/menagerie-generator/"
        @workspace.mkpath
        @destination = Pathname.new args[1]
        @top_level_destination = @destination
        @name = "noname"
        if args.length > 2
          @name = args[2]
          @destination = @destination + @name.downcase
        end
        @destination.mkpath unless @destination.exist?
      end

      def copy_static_files
        `cp -r lib/static/* #{@top_level_destination}`
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
        @summaries = summaries.sort
      end

      def find_resources
        header = time_series.first.open(&:readline).chomp
        header = header[1..-1]
        header = header.split /\s+/
        @units = header.map do |h|
          result = h.scan(/\((.*)\)/)[0]
          result = result.first if result
          result =  "" unless result
          result
        end
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
        <link rel="stylesheet" type="text/css" media="screen, projection" href="../css/style.css" />
        <script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js\"></script>
        <script src=\"../js/slides.min.jquery.js\"></script>
        <script>\n \$(function(){\n \$('#slides').slides({\n preload: true,\n });\n });\n </script>
        <title>#{name} Workflow</title>
        <div class="content">
        <h1>#{name} Workflow</h1>
        <section class="summary">
          <div id="slides">
            <div class="slides_container">
              <div class="slide"><div class="item"><img src="makeflowlog.png" /></div></div>
              <div class="slide"><div class="item"><img src="cpu.png" /></div></div>
              <div class="slide"><div class="item"><img src="proc.png" /></div></div>
              <div class="slide"><div class="item"><img src="memory.png" /></div></div>
              <div class="slide"><div class="item"><img src="disk.png" /></div></div>
              <div class="slide"><div class="item"><img src="io.png" /></div></div>
            </div>
            <a href=\"#\" class=\"prev\"><img src=\"../img/arrow-prev.png\" width=\"24\" height=\"43\" alt=\"Arrow Prev\"></a>
            <a href=\"#\" class=\"next\"><img src=\"../img/arrow-next.png\" width=\"24\" height=\"43\" alt=\"Arrow Next\"></a>
          </div>
        </section>
        INDEX
        sizes.sort_by! {|s| s.first}
        @resources.each do |r|
          output << %Q{<a href="#{r.to_s}_#{sizes.last.first}x#{sizes.last.last}_hist.png"><img src="#{r.to_s}_#{sizes.first.first}x#{sizes.first.last}_hist.png" /></a>\n}
        end
        output << "</div>"
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
          STDERR.puts "gnuplot not installed"
        end
        output
      end

      def histogram_format(width: 600, height: 600, resource: "", data_path: "/tmp")
        max = scale_maximum resource.to_s, @maximums[resource].max
        unit = @units[@resources.index(resource)]
        unit = " (#{unit})" unless unit == ""
        binwidth = 1
        binwidth = max/40 unless max <= 40
        %Q{set terminal png transparent size #{width},#{height}
        set bmargin 4
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
        set xlabel "#{resource.to_s}#{unit}" offset 0,-2 character
        set bmargin 7
        plot "#{data_path.to_s}" using (bin(\$1,binwidth)):(1.0) smooth freq w boxes lc rgb"#5aabbc"
        }
      end
  end
end
