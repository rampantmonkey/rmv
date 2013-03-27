require_relative '../menagerie_generator'

module MenagerieGenerator
  class HistogramBuilder
    def initialize resources, summaries, workspace, destination
      @resources = resources
      @summaries = summaries
      @workspace = workspace
      @destination = destination
    end

    def build sizes=[[600,600]], output=""
    end
    def find_groups
      groups = []
      summaries.each do |s|
        exe = s.executable_name
        groups << exe unless groups.include? exe
      end
      groups
    end

    private
      attr_reader :resources, :summaries, :workspace, :destination

      def find_maximums group
        max = Hash[ @resources.map {|r| [r,[]] }]
        summaries.each do |s|
          resources.each do |r|
            if s.executable_name == group
              tmp = s.send r.name.to_sym
              max[r].push tmp
            end
          end
        end
        max
      end

      def scale_maximum name, value
        value /= 1024 if name.match /byte/
        value
      end

      def write_maximum_values maximum_list, index
        base_path = workspace + "group#{index}"
        base_path.mkpath
        maximum_list.each do |m|
          path = base_path + m.first.name.to_s
          File.open(path, 'w:UTF-8') do |f|
            m.last.each do |line|
              line = yield( m.first.name, line) if block_given?
              f.puts line
            end
          end
        end
      end

      def gnuplot_format(width: 600, height: 600, resource: "", data_path: "/tmp", group: 0)
        max = scale_maximum resource.name.to_s, @grouped_maximums[group][resource].max
        unit = resource.unit
        image_path = destination + "group#{group}"
        image_path.mkpath
        image_path += "#{resource.name.to_s}_#{width}x#{height}_hist.png"
        binwidth = 1
        binwidth = max/40 unless max <= 40
        %Q{set terminal png transparent size #{width},#{height}
        set bmargin 4
        unset key

        set ylabel "Frequency"
        set output "#{image_path}"
        binwidth=#{binwidth}
        set boxwidth binwidth*0.9
        set style fill solid 0.5
        bin(x,width)=width*floor(x/width)
        set yrange [0:*]
        set xrange [0:*]
        set xtics right rotate by -45
        set xlabel "#{resource.name.to_s}#{unit}" offset 0,-2 character
        set bmargin 7
        plot "#{data_path.to_s}" using (bin(\$1,binwidth)):(1.0) smooth freq w boxes lc rgb"#5aabbc"
        }
      end
  end
end
