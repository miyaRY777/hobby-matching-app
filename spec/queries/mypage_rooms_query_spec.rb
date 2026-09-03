require "rails_helper"

RSpec.describe MypageRoomsQuery do
  describe ".call" do
    subject(:result) { described_class.call(profile:, page:) }

    let(:profile) { create(:profile) }
    let(:other_profile) { create(:profile) }
    let(:page) { 1 }

    it "発行した部屋を返す" do
      issued_room = create(:room, issuer_profile: profile)
      create(:room, issuer_profile: other_profile, label: "未参加の他人の部屋")

      expect(result).to include(issued_room)
      expect(result).to all(be_a(Room))
    end

    it "参加中の部屋を返す" do
      joined_room = create(:room, issuer_profile: other_profile, label: "参加中の部屋")
      membership = create(:room_membership, room: joined_room, profile: profile)
      create(:room, issuer_profile: other_profile, label: "未参加の他人の部屋")

      expect(result).to include(membership)
      expect(result).not_to include(joined_room)
    end

    it "created_at の降順で並ぶ" do
      older_issued = create(:room, issuer_profile: profile, created_at: 3.days.ago)
      joined_room = create(:room, issuer_profile: other_profile, created_at: 2.days.ago)
      membership = create(:room_membership, room: joined_room, profile: profile)
      newer_issued = create(:room, issuer_profile: profile, created_at: 1.day.ago)

      expect(result.to_a).to eq([ newer_issued, membership, older_issued ])
    end

    it "Kaminari でページ分割する" do
      create_list(:room, described_class::PER + 1, issuer_profile: profile)

      page1 = described_class.call(profile:, page: 1)
      page2 = described_class.call(profile:, page: 2)

      expect(page1).to be_a(Kaminari::PaginatableArray)
      expect(page1.size).to eq(described_class::PER)
      expect(page2.size).to eq(1)
      expect(page1.current_page).to eq(1)
      expect(page2.current_page).to eq(2)
    end
  end
end