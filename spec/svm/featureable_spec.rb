require 'ostruct'
require 'svm/featureable'

module SVM
  describe Featureable do
    describe "#to_feature" do
      it "transforms feature_names into vector" do
        class FeatureTest < OpenStruct
          include Featureable
          self.feature_names = %w(velocity x_coord y_coord)
        end

        test = FeatureTest.new
        test.velocity = 0.5
        test.x_coord = 1
        test.y_coord = 0
        expect(test.to_feature).to eq([0.5, 1, 0])
      end
    end

  end

end