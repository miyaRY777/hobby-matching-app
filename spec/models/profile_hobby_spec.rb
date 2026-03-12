# spec/models/profile_hobby_spec.rb
require "rails_helper"

RSpec.describe ProfileHobby, type: :model do
  describe "description バリデーション" do
    let(:profile_hobby) { build(:profile_hobby) }

    it "nilは有効（任意）" do
      profile_hobby.description = nil
      expect(profile_hobby).to be_valid
    end

    it "空文字は有効" do
      profile_hobby.description = ""
      expect(profile_hobby).to be_valid
    end

    it "200字以内は有効" do
      profile_hobby.description = "a" * 200
      expect(profile_hobby).to be_valid
    end

    it "201字以上は無効" do
      profile_hobby.description = "a" * 201
      expect(profile_hobby).not_to be_valid
      expect(profile_hobby.errors[:description]).to be_present
    end
  end

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
