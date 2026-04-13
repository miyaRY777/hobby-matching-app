require "rails_helper"

RSpec.describe HobbyParentTag, type: :model do
  describe "アソシエーション" do
    it "hobby に属する" do
      association = described_class.reflect_on_association(:hobby)

      expect(association.macro).to eq(:belongs_to)
    end

    it "parent_tag に属する" do
      association = described_class.reflect_on_association(:parent_tag)

      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "バリデーション" do
    let(:chat_tag) { create(:parent_tag, room_type: :chat) }
    let(:chat_tag2) { create(:parent_tag, room_type: :chat) }
    let(:game_tag) { create(:parent_tag, room_type: :game) }
    let(:hobby) { create(:hobby) }

    it "同一 room_type に 2 つ目の parent_tag を紐付けようとすると無効になる" do
      create(:hobby_parent_tag, hobby:, parent_tag: chat_tag)
      duplicate = described_class.new(hobby:, parent_tag: chat_tag2)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:hobby_id]).not_to be_empty
    end

    it "異なる room_type なら同じ hobby に複数の parent_tag を紐付けられる" do
      create(:hobby_parent_tag, hobby:, parent_tag: chat_tag)
      another = described_class.new(hobby:, parent_tag: game_tag)

      expect(another).to be_valid
    end

    it "同じ (hobby_id, parent_tag_id) の重複は無効になる" do
      create(:hobby_parent_tag, hobby:, parent_tag: chat_tag)
      duplicate = described_class.new(hobby:, parent_tag: chat_tag)

      expect(duplicate).not_to be_valid
    end
  end

  describe "before_validation :sync_room_type" do
    it "parent_tag の room_type を自動セットする" do
      game_tag = create(:parent_tag, room_type: :game)
      hobby_parent_tag = described_class.new(hobby: create(:hobby), parent_tag: game_tag)

      hobby_parent_tag.valid?

      expect(hobby_parent_tag.room_type).to eq("game")
    end
  end
end
