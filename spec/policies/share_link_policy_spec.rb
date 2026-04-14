require "rails_helper"

RSpec.describe ShareLinkPolicy do
  # 部屋オーナー
  let(:room_owner_user)    { create(:user) }
  let(:room_owner_profile) { create(:profile, user: room_owner_user) }
  let(:room)               { create(:room, issuer_profile: room_owner_profile) }

  # 閲覧者（オーナー以外）
  let(:viewer_user)    { create(:user) }
  let(:viewer_profile) { create(:profile, user: viewer_user) }

  # 有効なリンク（期限内）と期限切れリンク
  let(:active_link)  { create(:share_link, room: room, expires_at: 1.year.from_now) }
  let(:expired_link) { create(:share_link, room: room, expires_at: 1.hour.ago) }

  def policy(share_link, user)
    described_class.new(share_link, user: user)
  end

  describe "#show?" do
    context "有効なリンク（期限内）の場合" do
      it "非メンバーでも true を返す" do
        # 閲覧者は未参加
        expect(policy(active_link, viewer_user).show?).to be true
      end
    end

    context "ロック中の部屋の場合" do
      before { room.update!(locked: true) }

      it "非メンバー・非オーナーは false を返す" do
        expect(policy(active_link, viewer_user).show?).to be false
      end

      it "既存メンバーは true を返す" do
        create(:room_membership, room: room, profile: viewer_profile)
        expect(policy(active_link, viewer_user).show?).to be true
      end

      it "オーナーは true を返す" do
        expect(policy(active_link, room_owner_user).show?).to be true
      end
    end

    context "期限切れリンクの場合" do
      it "非メンバーは false を返す" do
        # 閲覧者は未参加かつリンクは期限切れ → アクセス不可
        expect(policy(expired_link, viewer_user).show?).to be false
      end

      it "既存メンバーは true を返す" do
        # 閲覧者がすでに参加済み → 期限切れでも閲覧継続可
        create(:room_membership, room: room, profile: viewer_profile)
        expect(policy(expired_link, viewer_user).show?).to be true
      end
    end
  end

  describe "#join?" do
    context "アンロック中の部屋の場合" do
      before { room.update!(locked: false) }

      it "非メンバーでも true を返す" do
        # 未参加でもアンロック中なら参加可
        expect(policy(active_link, viewer_user).join?).to be true
      end
    end

    context "ロック中の部屋の場合" do
      before { room.update!(locked: true) }

      it "非メンバー・非オーナーは false を返す" do
        # 未参加かつオーナーでない → 参加拒否
        expect(policy(active_link, viewer_user).join?).to be false
      end

      it "既存メンバーは true を返す" do
        # すでに参加済みならロック中でも通過
        create(:room_membership, room: room, profile: viewer_profile)
        expect(policy(active_link, viewer_user).join?).to be true
      end

      it "オーナーは true を返す" do
        # 部屋の作成者はロック中でも通過
        expect(policy(active_link, room_owner_user).join?).to be true
      end
    end
  end
end
