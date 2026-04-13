# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hobby, type: :model do
  describe "バリデーション" do
    it "name が空だと無効になる" do
      hobby = described_class.new(name: nil)
      expect(hobby).to be_invalid
    end

    it "同じ name は重複して保存できない" do
      described_class.create!(name: "rails")
      hobby = described_class.new(name: "rails")
      expect(hobby).to be_invalid
    end
  end

  describe "関連" do
    it "has_many :hobby_parent_tags を持つ" do
      association = described_class.reflect_on_association(:hobby_parent_tags)

      expect(association.macro).to eq(:has_many)
    end

    it "has_many :parent_tags through :hobby_parent_tags を持つ" do
      association = described_class.reflect_on_association(:parent_tags)

      expect(association.macro).to eq(:has_many)
    end

    it "hobby を削除すると hobby_parent_tags も削除される" do
      hobby = create(:hobby)
      parent_tag = create(:parent_tag, room_type: :chat)
      create(:hobby_parent_tag, hobby:, parent_tag:)

      expect { hobby.destroy }.to change(HobbyParentTag, :count).by(-1)
    end

    it "profile_hobbies が存在する場合は削除できない" do
      hobby = create(:hobby)
      create(:profile_hobby, hobby:)

      expect(hobby.destroy).to be false
      expect(hobby.errors[:base]).not_to be_empty
      expect(described_class.exists?(hobby.id)).to be true
    end
  end

  describe "normalized_name" do
    it "保存時に正規化される（全角→半角、大文字→小文字、前後空白除去）" do
      hobby = described_class.create!(name: "　Ｒｕｂｙ　")
      expect(hobby.normalized_name).to eq("ruby")
    end

    it "日本語の全角カナはそのまま保持される" do
      hobby = described_class.create!(name: "プログラミング")
      expect(hobby.normalized_name).to eq("プログラミング")
    end
  end
end
