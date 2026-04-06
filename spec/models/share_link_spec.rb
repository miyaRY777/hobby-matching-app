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

  it "作成時にexpires_atが現在時刻から24時間後に設定される" do
    room = create(:room)
    share_link = described_class.create(room: room)

    expect(share_link.expires_at).to be_within(5.seconds).of(24.hours.from_now)
  end

  describe "no_expiry フラグ" do
    it "no_expiry: true で作成すると expires_at が nil のまま保存される" do
      # 部屋を用意
      room = create(:room)

      # no_expiry フラグを立てて作成
      share_link = described_class.create!(room: room, no_expiry: true)

      # expires_at が nil のまま保存されること
      expect(share_link.expires_at).to be_nil
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
