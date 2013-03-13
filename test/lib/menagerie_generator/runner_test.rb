require_relative '../../test_helper'

module MenagerieGenerator
  class TestRunner < Test::Unit::TestCase
    context "Initialization" do
      should "set source and destination" do
        r = Runner.new ["a", "b"]
        assert_equal "a", r.source
        assert_equal "b", r.destination
      end

      should "gracefully discard extra arguments" do
        r = Runner.new ["a", "b", "c"]
        assert_equal "a", r.source
        assert_equal "b", r.destination
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
  end
end
