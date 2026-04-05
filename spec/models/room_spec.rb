require "rails_helper"

RSpec.describe Room, type: :model do
  it "発行者プロフィール（issuer_profile）がない場合は無効にする" do
    room = described_class.new(issuer_profile: nil)

    expect(room).not_to be_valid
  end

  describe "room_type enum" do
    it "デフォルト値が chat である" do
      room = create(:room)

      expect(room.room_type).to eq("chat")
    end

    it "study に変更できる" do
      room = create(:room)

      room.study!

      expect(room).to be_study
    end

    it "game に変更できる" do
      room = create(:room)

      room.game!

      expect(room).to be_game
    end

    it "スコープで絞り込みできる" do
      chat_room = create(:room)
      study_room = create(:room)
      study_room.study!

      expect(described_class.chat).to include(chat_room)
      expect(described_class.chat).not_to include(study_room)
      expect(described_class.study).to include(study_room)
    end

    it "不正な値で ArgumentError が発生する" do
      expect { create(:room).room_type = "invalid" }.to raise_error(ArgumentError)
    end
  end

  describe "locked カラム" do
    it "デフォルト値が false である" do
      room = create(:room)

      expect(room.locked).to be false
    end
  end

  it "has associations" do
    room = described_class.reflect_on_association(:issuer_profile)

    expect(room.macro).to eq(:belongs_to)
    expect(described_class.reflect_on_association(:room_memberships).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:profiles).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:share_link).macro).to eq(:has_one)
  end
end
