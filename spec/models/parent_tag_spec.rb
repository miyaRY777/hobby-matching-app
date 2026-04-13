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
      described_class.create!(name: "テスト重複A", slug: "test-dup", room_type: :chat)
      parent_tag = described_class.new(name: "テスト重複B", slug: "test-dup", room_type: :chat)
      expect(parent_tag).to be_invalid
    end

    it "room_type が nil 同士でも同じ slug は重複して保存できない" do
      described_class.create!(name: "テスト未分類A", slug: "test-uncat", room_type: nil)
      parent_tag = described_class.new(name: "テスト未分類B", slug: "test-uncat", room_type: nil)
      expect(parent_tag).to be_invalid
    end

    it "room_type が異なれば同じ slug で保存できる" do
      described_class.create!(name: "テスト異種A", slug: "test-cross", room_type: :chat)
      parent_tag = described_class.new(name: "テスト異種B", slug: "test-cross", room_type: :study)
      expect(parent_tag).to be_valid
    end

    it "同じ room_type + name の組み合わせは重複して保存できない" do
      described_class.create!(name: "テスト名重複", slug: "test-name-dup-a", room_type: :chat)
      parent_tag = described_class.new(name: "テスト名重複", slug: "test-name-dup-b", room_type: :chat)
      expect(parent_tag).to be_invalid
    end

    it "room_type が異なれば同じ name で保存できる" do
      described_class.create!(name: "テスト名異種", slug: "test-name-cross-a", room_type: :chat)
      parent_tag = described_class.new(name: "テスト名異種", slug: "test-name-cross-b", room_type: :study)
      expect(parent_tag).to be_valid
    end
  end

  describe "enum" do
    it "room_type が chat/study/game を持つ" do
      expect(described_class.room_types).to eq("chat" => 0, "study" => 1, "game" => 2)
    end
  end

  describe "関連" do
    it "has_many :hobby_parent_tags を持つ" do
      association = described_class.reflect_on_association(:hobby_parent_tags)

      expect(association.macro).to eq(:has_many)
    end

    it "has_many :hobbies through :hobby_parent_tags を持つ" do
      association = described_class.reflect_on_association(:hobbies)

      expect(association.macro).to eq(:has_many)
    end

    it "hobby_parent_tags がある場合は削除できない" do
      parent_tag = described_class.create!(name: "テスト削除", slug: "test-delete", room_type: :chat)
      hobby = create(:hobby, name: "テスト趣味C")
      create(:hobby_parent_tag, hobby:, parent_tag:)

      expect { parent_tag.destroy }.not_to change(described_class, :count)
      expect(parent_tag.errors[:base]).to be_present
    end
  end

  describe "デフォルト値" do
    it "position のデフォルト値が 0 になる" do
      parent_tag = described_class.create!(name: "テスト位置", slug: "test-pos", room_type: :chat)
      expect(parent_tag.position).to eq(0)
    end
  end
end
