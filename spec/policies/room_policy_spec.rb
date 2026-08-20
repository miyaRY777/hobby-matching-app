require "rails_helper"

# 部屋の閲覧可否（RoomPolicy#show?）を検証する。
# 招待リンクの期限は ShareLinkPolicy の責務なので、ここでは見ない。
RSpec.describe RoomPolicy do
  # 部屋の作成者
  let(:room_owner_user)    { create(:user) }
  let(:room_owner_profile) { create(:profile, user: room_owner_user) }
  let(:room)               { create(:room, issuer_profile: room_owner_profile, locked: false) }

  # 部屋作成者以外の閲覧者
  let(:viewer_user)    { create(:user) }
  let(:viewer_profile) { create(:profile, user: viewer_user) }

  def policy(record, user)
    described_class.new(record, user: user)
  end

  describe "#show?" do
    context "公開部屋の場合" do
      it "未参加でも true を返す" do
        # プロフィールはあるが RoomMembership はない（覗くだけ）
        viewer_profile
        expect(policy(room, viewer_user).show?).to be true
      end

      it "プロフィール未作成でも true を返す" do
        # 参加にはプロフィールが要るが、見るだけなら不要
        user_without_profile = create(:user)
        expect(policy(room, user_without_profile).show?).to be true
      end
    end

    context "非公開部屋の場合" do
      before { room.update!(locked: true) }

      it "未参加は false を返す" do
        # 非公開は外に存在しない扱い（後続の HTTP では 404）
        expect(policy(room, viewer_user).show?).to be false
      end

      it "既存メンバーは true を返す" do
        # すでに中にいる人は、非公開でも見続けられる
        create(:room_membership, room: room, profile: viewer_profile)
        expect(policy(room, viewer_user).show?).to be true
      end

      it "作成者は true を返す" do
        # membership の有無に関わらず、作成者は非公開部屋も閲覧できる
        expect(policy(room, room_owner_user).show?).to be true
      end
    end
  end
end
