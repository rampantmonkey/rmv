require_relative '../../test_helper'

module MenagerieGenerator
  class TestRunner < Test::Unit::TestCase
    context "Initialization" do
      should "set source and destination" do
        r = Runner.new ["a", "b"]
        assert_equal "a", r.source.to_s
        assert_equal "b", r.destination.to_s
      end

      should "gracefully discard extra arguments" do
        r = Runner.new ["a", "b", "c"]
        assert_equal "a", r.source.to_s
        assert_equal "b", r.destination.to_s
      end

      should "throw an error" do
        assert_raise ArgumentError do
          r = Runner.new []
        end
        assert_raise ArgumentError do
          r = Runner.new ["a"]
        end
      end
    end

    context "run" do
      setup do
        @r = Runner.new ["test/data/blast", "a"]
        @r.run
      end

      should "find 9 time series files" do
        assert_equal 9, @r.time_series.size
      end

      should "find 9 summary files" do
        assert_equal 9, @r.summaries.size
      end

      should "process header line" do
        expected = [:"wall_clock(seconds)",
                    :concurrent_processes,
                    :"cpu_time(seconds)",
                    :"virtual_memory(kB)",
                    :"resident_memory(kB)",
                    :bytes_read,
                    :bytes_written,
                    :workdir_number_files_dirs,
                    :"workdir_footprint(MB)"]
        assert_equal expected, @r.resources
      end
    end
  end
end
