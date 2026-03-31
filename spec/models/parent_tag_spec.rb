# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParentTag, type: :model do
  describe "バリデーション" do
    it "name が空だと無効になる" do
      parent_tag = described_class.new(name: nil, slug: "test")
      expect(parent_tag).to be_invalid
    end

    it "slug が空だと無効になる" do
      parent_tag = described_class.new(name: "テスト", slug: nil)
      expect(parent_tag).to be_invalid
    end

    it "同じ room_type + slug の組み合わせは重複して保存できない" do
      described_class.create!(name: "アニメ", slug: "anime", room_type: :chat)
      parent_tag = described_class.new(name: "アニメ2", slug: "anime", room_type: :chat)
      expect(parent_tag).to be_invalid
    end

    it "room_type が nil 同士でも同じ slug は重複して保存できない" do
      described_class.create!(name: "未分類", slug: "uncategorized", room_type: nil)
      parent_tag = described_class.new(name: "未分類2", slug: "uncategorized", room_type: nil)
      expect(parent_tag).to be_invalid
    end

    it "room_type が異なれば同じ slug で保存できる" do
      described_class.create!(name: "アニメ", slug: "anime", room_type: :chat)
      parent_tag = described_class.new(name: "アニメ", slug: "anime", room_type: :study)
      expect(parent_tag).to be_valid
    end
  end

  describe "enum" do
    it "room_type が chat/study/game を持つ" do
      expect(described_class.room_types).to eq("chat" => 0, "study" => 1, "game" => 2)
    end
  end

  describe "関連" do
    it "hobbies を複数持てる" do
      parent_tag = described_class.create!(name: "アニメ", slug: "anime", room_type: :chat)
      parent_tag.hobbies.create!(name: "呪術廻戦")
      parent_tag.hobbies.create!(name: "ワンピース")
      expect(parent_tag.hobbies.count).to eq(2)
    end

    it "子 hobby がある場合は削除できない" do
      parent_tag = described_class.create!(name: "アニメ", slug: "anime", room_type: :chat)
      parent_tag.hobbies.create!(name: "呪術廻戦")
      expect { parent_tag.destroy }.not_to change(described_class, :count)
      expect(parent_tag.errors[:base]).to be_present
    end
  end

  describe "デフォルト値" do
    it "position のデフォルト値が 0 になる" do
      parent_tag = described_class.create!(name: "アニメ", slug: "anime", room_type: :chat)
      expect(parent_tag.position).to eq(0)
    end
  end
end
