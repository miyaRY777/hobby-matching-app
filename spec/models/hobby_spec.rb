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
    it "parent_tag に属することができる" do
      parent_tag = ParentTag.create!(name: "アニメ", slug: "anime", room_type: :chat)
      hobby = described_class.create!(name: "呪術廻戦", parent_tag: parent_tag)
      expect(hobby.parent_tag).to eq(parent_tag)
    end

    it "parent_tag が nil でも有効（optional）" do
      hobby = described_class.new(name: "その他の趣味", parent_tag: nil)
      expect(hobby).to be_valid
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
