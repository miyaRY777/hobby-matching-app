require "rails_helper"

RSpec.describe RoomCreator do
  describe ".call" do
    let(:issuer_profile) { create(:profile) }
    let(:room_params) { { label: "新しい部屋", room_type: "chat", locked: false } }
    let(:expires_in) { nil }

    subject(:result) do
      described_class.call(
        issuer_profile: issuer_profile,
        room_params: room_params,
        expires_in: expires_in
      )
    end

    it "Room, RoomMembership, ShareLink を作成する" do
      expect { result }
        .to change(Room, :count).by(1)
        .and change(RoomMembership, :count).by(1)
        .and change(ShareLink, :count).by(1)

      expect(result[:success]).to be true
      expect(result[:room]).to be_persisted

      room = result[:room]
      expect(room.issuer_profile).to eq(issuer_profile)
      expect(room.room_memberships.pluck(:profile_id)).to include(issuer_profile.id)
      expect(room.share_link).to be_present
    end

    context 'expires_in が "7d" のとき' do
      let(:expires_in) { "7d" }

      it "expires_in を正規化して ShareLink に反映する" do
        result

        share_link = result[:room].share_link
        expect(share_link.expires_in).to eq("7d")
        expect(share_link.expires_at).to be_within(5.seconds).of(7.days.from_now)
      end
    end

    context 'expires_in が "none" のとき' do
      let(:expires_in) { "none" }

      it "無効な expires_in は nil として扱う" do
        result

        share_link = result[:room].share_link
        expect(share_link.expires_in).to be_nil
        expect(share_link.expires_at).to be_nil
      end
    end

    context "label が空のとき" do
      let(:room_params) { { label: "", room_type: "chat", locked: false } }

      it "バリデーション失敗時はレコードを増やさない" do
        expect { result }.not_to change(Room, :count)

        expect(RoomMembership.count).to eq(0)
        expect(ShareLink.count).to eq(0)
        expect(result[:success]).to be false
        expect(result[:room]).not_to be_persisted
        expect(result[:room].errors[:label]).to be_present
      end
    end
  end
end