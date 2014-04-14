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

      it "transforms feature_names into vector, using feature_lambdas" do
        class FeatureTest < OpenStruct
          include Featureable
          self.feature_names = %w(velocity x_coord y_coord)
          self.feature_lambdas = {
              x_coord: lambda {|x| x + 1}
          }
        end
        test = FeatureTest.new
        test.velocity = 0.5
        test.x_coord = 1
        test.y_coord = 0
        expect(test.to_feature).to eq([0.5, 2, 0])
      end

      it "transforms feature_ordinals into 0-1 vector" do
        class FeatureTest < OpenStruct
          include Featureable
          self.feature_names = %w(velocity x_coord y_coord status)
          self.feature_lambdas = {
              x_coord: lambda {|x| x + 1}
          }
          self.feature_ordinals = {
              status: [nil, "on", "off"]
          }
        end
        test = FeatureTest.new
        test.velocity = 0.5
        test.x_coord = 1
        test.y_coord = 0
        expect(test.to_feature).to eq([0.5, 2, 0, 1, 0, 0])

        test.velocity = 0.5
        test.x_coord = 1
        test.y_coord = 0
        test.status = "off"
        expect(test.to_feature).to eq([0.5, 2, 0, 0, 0, 1])

      end


    end

  end

end