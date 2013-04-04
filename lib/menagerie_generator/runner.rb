require_relative '../menagerie_generator'

require 'pathname'
require 'yaml'
require 'open3'

module MenagerieGenerator
  class Runner
    attr_reader :debug, :source, :destination, :time_series, :resources, :workspace, :name, :tasks

    def initialize argv
      options = Options.new argv
      process_arguments options
    end

    def run
      find_files
      find_resources
      create_histograms
      create_group_resource_summaries
      make_combined_time_series
      plot_makeflow_log source + 'Makeflow.makeflowlog'
      make_index [[1250,500]], [[600,600],[250,250]]
      copy_static_files
      remove_temp_files unless debug
    end

    private
      def remove_temp_files
        `rm -rf #{workspace}`
      end

      def create_group_resource_summaries histogram_size=[600,600]
        @groups.each do |g|
          @resources.each do |r|
            path = @destination + "#{g}" + "#{r}"
            path.mkpath
            page = <<-INDEX
            <!doctype html>
            <meta charset="UTF-8">
            <meta name="viewport" content="initial-scale=1.0, width=device-width" />
            <link rel="stylesheet" type="text/css" media="screen, projection" href="../../../css/style.css" />
            <title>#{name} Workflow</title>
            <div class="content">
            <h1><a href="../../index.html">#{name}</a> - #{g} - #{r}</h1>
            <img src="../#{r.to_s}_#{histogram_size.first}x#{histogram_size.last}_hist.png" />
            <table>
            <tr><th>Rule Id</th><th>Maximum #{r}</th></tr>
            INDEX

            lines = []
            @tasks.each { |t| lines << t if t.executable_name == g }

            lines.sort_by{ |t| t.grab r.name }.each do |t|
              scaled_resource = t.grab r.name
              scaled_resource /= 1024.0 if r.name.match /footprint/
              scaled_resource /= 1024.0 if r.name.match /memory/
              scaled_resource /= 1073741824.0 if r.name.match /byte/
              page << "<tr><td>#{t.rule_id}</td><td>#{scaled_resource.round 3}</td></tr>\n"
            end

            path += "index.html"
            path.open("w:UTF-8") { |f| f.puts page }
          end
        end
      end

      def find_start_time
        t1 = tasks.first
        lowest = t1.grab :start
        t2 = tasks.last
        highest = t2.grab :start
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
            gnuplot {|io| io.puts time_series_format(width: width, height: height, resource: r, data_path: workspace+"aggregate_#{r.name.to_s}")}
          end
        end
      end

      def time_series_format(width: 1250, height: 500, resource: "", data_path: "/tmp")
        unit = resource.unit
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
        %w(source destination workspace).each do |w|
         instance_variable_set "@#{w}", args.send(w)
        end

        @name = args.name
        @debug = args.debug

        @workspace.mkpath
        @top_level_destination = @destination
        @destination = @destination + @name.downcase
        @destination.mkpath unless @destination.exist?
      end

      def copy_static_files
        `cp -r lib/static/* #{@top_level_destination}`
      end

      def find_files
        time_series_paths = []
        summary_paths = []
        Pathname.glob(@source + "log-rule*") do |path|
          if path.to_s.match /.*summary/
            summary_paths << path
          else
            time_series_paths << path
          end
        end
        @time_series = time_series_paths
        @tasks = TaskCollection.new summary_paths, time_series_paths
      end

      def find_resources
        header = time_series.first.open(&:readline).chomp
        header = header[1..-1]
        @resources = Resources.new header
      end

      def create_histograms
        builder = HistogramBuilder.new resources, workspace, destination, tasks
        @groups = builder.find_groups
        builder.build([[600,600],[250,250]]).map do |b|
          gnuplot { |io| io.puts b }
        end
      end

      def make_index summary_sizes = [[1250, 500]], histogram_sizes=[[600,600]]
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
              <div class="slide"><div class="item"><img src="makeflowlog_1250x500.png" /></div></div>
        INDEX

        summary_sizes.sort_by!{|s| s.first}
        summary_large = summary_sizes.last
        resources.each_with_index do |r, i|
          output << %Q{ <div class="slide"><div class="item"><img src="#{r.to_s}_#{summary_large.first}x#{summary_large.last}_aggregate.png" /></div></div>\n} unless i == 0
        end

        output << <<-INDEX
           </div>
            <a href=\"#\" class=\"prev\"><img src=\"../img/arrow-prev.png\" width=\"24\" height=\"43\" alt=\"Arrow Prev\"></a>
            <a href=\"#\" class=\"next\"><img src=\"../img/arrow-next.png\" width=\"24\" height=\"43\" alt=\"Arrow Next\"></a>
          </div>
        </section>
        INDEX
        histogram_sizes.sort_by! {|s| s.first}
        hist_small = histogram_sizes.first
        hist_large = histogram_sizes.last
        @groups.each_with_index do |g, i|
          output << %Q{\n<hr />\n} if i > 0
          output << %Q{\n<h2>#{g}</h2>}
          @resources.each do |r|
            output << %Q{<a href="#{g}/#{r.to_s}/index.html"><img src="#{g}/#{r.to_s}_#{hist_small.first}x#{hist_small.last}_hist.png" /></a>\n}
          end
        end
        output << "</div>"
        path.open("w:UTF-8") { |f| f.puts output }
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

      def plot_makeflow_log log_file
        output_path = destination + 'makeflowlog.png'
        mflog = MakeflowLog.from_file log_file
        summary_data_file = workspace + "summarydata"
        summary_data_file.open("w:UTF-8") { |f| f.puts mflog }
        gnuplot {|io| io.puts mflog.gnuplot_format(data_path: summary_data_file, output_path: destination) }
      end
  end
end
