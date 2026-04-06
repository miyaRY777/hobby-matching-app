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
