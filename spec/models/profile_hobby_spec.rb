# spec/models/profile_hobby_spec.rb
require "rails_helper"

RSpec.describe ProfileHobby, type: :model do
  describe "バリデーション" do
    it "同じ profile と hobby の組み合わせは重複して保存できない" do
      profile = create(:profile)
      hobby   = create(:hobby)

      described_class.create!(profile:, hobby:)

      dup = described_class.new(profile:, hobby:)
      expect(dup).to be_invalid
    end
  end
end
