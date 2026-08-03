require "rails_helper"

RSpec.describe RoomParentTagProfilesQuery do
  subject(:profiles) { described_class.call(room:, parent_tag:) }

  let(:room) { create(:room, room_type: :chat) }
  let(:parent_tag) { create(:parent_tag, room_type: :chat) }
  let(:other_parent_tag) { create(:parent_tag, room_type: :chat) }
  let(:matching_hobby) { create(:hobby) }
  let(:second_matching_hobby) { create(:hobby) }
  let(:other_hobby) { create(:hobby) }

  before do
    create(:hobby_parent_tag, hobby: matching_hobby, parent_tag:)
    create(:hobby_parent_tag, hobby: second_matching_hobby, parent_tag:)
    create(:hobby_parent_tag, hobby: other_hobby, parent_tag: other_parent_tag)
  end

  it "対象親タグの趣味を持つ部屋メンバーだけをID昇順で返す" do
    first_profile = create(:profile)
    second_profile = create(:profile)
    unrelated_profile = create(:profile)
    outside_profile = create(:profile)

    [ second_profile, first_profile, unrelated_profile ].each do |profile|
      create(:room_membership, room:, profile:)
    end
    create(:profile_hobby, profile: first_profile, hobby: matching_hobby)
    create(:profile_hobby, profile: second_profile, hobby: matching_hobby)
    create(:profile_hobby, profile: unrelated_profile, hobby: other_hobby)
    create(:profile_hobby, profile: outside_profile, hobby: matching_hobby)

    expect(profiles).to eq([ first_profile, second_profile ])
  end

  it "同じ親タグの趣味を複数持つプロフィールを重複して返さない" do
    profile = create(:profile)
    create(:room_membership, room:, profile:)
    create(:profile_hobby, profile:, hobby: matching_hobby)
    create(:profile_hobby, profile:, hobby: second_matching_hobby)

    expect(profiles.to_a).to eq([ profile ])
  end
end
