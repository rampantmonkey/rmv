require_relative '../../test_helper'

module MenagerieGenerator
  class TestVersion < Test::Unit::TestCase
    context "version" do
      should "be defined" do
        assert_not_nil MenagerieGenerator::VERSION
      end
    end
  end
end
