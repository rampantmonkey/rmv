require_relative '../menagerie_generator'

module MenagerieGenerator
  class Resources
    def initialize  header
      @r = header.split(/\s+/).map do |h|
        unit = h.scan(/\((.*)\)/)[0]
        unit = unit.first if unit
        unit = "" unless unit
        name = translate_resource_name h.gsub(/\(.*\)/, '')
        Resource.new name, unit
      end
    end

    def map &b
      @r.map &b
    end

    def each &b
      @r.each &b
    end

    def index v
      @r.index v
    end

    def each_with_index &b
      @r.each_with_index &b
    end

    def to_ary
      @r
    end

    private
      class Resource < Struct.new(:name, :unit)
        def to_s
          name.to_s
        end
      end

      def translate_resource_name name
        name.gsub /clock/, 'time'
      end
  end
end
