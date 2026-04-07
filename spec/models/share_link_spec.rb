require "rails_helper"

RSpec.describe ShareLink, type: :model do
  it "roomがない場合は無効になる" do
    share_link = described_class.new(room: nil)

    expect(share_link).not_to be_valid
  end

  it "作成時に自動でトークンが生成される" do
    room = create(:room)
    share_link = described_class.create(room: room)

    expect(share_link.token).to be_present
  end

  describe "#regenerate!" do
    it "token が新しい値に更新される" do
      # 既存の token を持つ共有リンクを用意
      share_link = create(:share_link, room: create(:room), token: "old_token")

      share_link.regenerate!

      # token が変わっていること
      expect(share_link.reload.token).not_to eq("old_token")
    end

    it "expires_in: '24h' のとき expires_at が 24 時間後に更新される" do
      # 期限切れの共有リンク（expires_in: "24h"）を用意
      share_link = create(:share_link, room: create(:room), expires_in: "24h", expires_at: 1.day.ago)

      share_link.regenerate!

      # expires_at が 24 時間後になっていること
      expect(share_link.reload.expires_at).to be_within(5.seconds).of(24.hours.from_now)
    end

    it "expires_in: nil のとき expires_at が nil になる" do
      # expires_in が nil（無期限）の共有リンクを用意
      share_link = create(:share_link, room: create(:room), expires_in: nil, expires_at: 1.day.from_now)

      share_link.regenerate!

      # expires_at が nil になっていること
      expect(share_link.reload.expires_at).to be_nil
    end
  end

  describe "#expired?" do
    it "expires_at が nil のとき false を返す" do
      # 期限なしの共有リンクを用意
      share_link = build(:share_link, expires_at: nil)

      # 期限切れではないと判定されること
      expect(share_link.expired?).to be false
    end

    it "expires_at が過去のとき true を返す" do
      # 期限切れの共有リンクを用意
      share_link = build(:share_link, expires_at: 1.hour.ago)

      # 期限切れと判定されること
      expect(share_link.expired?).to be true
    end

    it "expires_at が未来のとき false を返す" do
      # 有効な共有リンクを用意
      share_link = build(:share_link, expires_at: 1.hour.from_now)

      # 期限切れではないと判定されること
      expect(share_link.expired?).to be false
    end
  end
end
