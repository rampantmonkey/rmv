require_relative '../../../lib/rmv/number.rb'

module RMV
  describe Number do
    it "accepts a valid value and unit" do
      n = Number.new 1024, 'KB'
      n.value.should eq 1024
      n.unit.should eq 'KB'
    end

    it "discards unknown units" do
      n = Number.new 999, 'procs'
      n.value.should eq 999
      n.unit.should eq ''
    end

    it "returns the prefix of a valid unit" do
      n = Number.new 385.2, 'MB'
      n.prefix.should eq 'M'
    end

    context "#base_value" do
      it "converts kilo" do
        n = Number.new 2, 'KB'
        n.base_value.should eq 2048
      end

      it "converts mega" do
        n = Number.new 4, 'MB'
        n.base_value.should eq 4_194_304
      end

      it "converts giga" do
        n = Number.new 3, 'GB'
        n.base_value.should eq 3_221_225_472
      end

      it "converts tera" do
        n = Number.new 7, 'TB'
        n.base_value.should eq 7_696_581_394_432
      end
    end

    context "#in" do
      let(:n) { Number.new 42_000_000, 'KB' }

      it "converts to kilo" do
        n.in('K').should eq 42_000_000
      end

      it "converts to mega" do
        n.in('M').should eq 41_015.625
      end

      it "converts to giga" do
        n.in('G').round(9).should eq 40.054321289
      end

      it "converts to tera" do
        n.in('T').round(9).should eq 0.039115548
      end
    end
  end
end
