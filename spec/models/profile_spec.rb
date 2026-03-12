require "rails_helper"

RSpec.describe Profile, type: :model do
  it "has room-related associations" do
    expect(described_class.reflect_on_association(:room_memberships).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:joined_rooms).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:issued_rooms).macro).to eq(:has_many)
  end

  describe "hobbies_text バリデーション" do
    let(:profile) { build(:profile) }

    it "10個以下のタグは有効" do
      profile.hobbies_text = (1..10).map { |i| "タグ#{i}" }.join(",")
      expect(profile).to be_valid
    end

    it "11個以上のタグは無効" do
      profile.hobbies_text = (1..11).map { |i| "タグ#{i}" }.join(",")
      expect(profile).not_to be_valid
      expect(profile.errors[:hobbies_text]).to be_present
    end

    it "hobbies_textが未設定の場合はバリデーションをスキップする" do
      profile.hobbies_text = nil
      expect(profile).to be_valid
    end
  end

  describe "#update_hobbies_from" do
    it "カンマ区切り入力から hobby を作成/取得し、profile の紐付けを全置換する" do
      profile = create(:profile)

      old = create(:hobby, name: "old")
      create(:profile_hobby, profile:, hobby: old)

      profile.update_hobbies_from("rails, ruby ,Ruby")

      expect(profile.hobbies.pluck(:name)).to match_array(%w[rails ruby])
    end

    it "空入力なら hobbies を空にする（全削除）" do
      profile = create(:profile)
      create(:profile_hobby, profile:, hobby: create(:hobby, name: "rails"))

      profile.update_hobbies_from("   ")

      expect(profile.hobbies).to be_empty
    end

    it "既存の Hobby は再利用する（件数が増えすぎない）" do
      profile = create(:profile)
      create(:hobby, name: "rails")

      expect { profile.update_hobbies_from("rails") }
        .not_to change(Hobby, :count)

      expect(profile.hobbies.pluck(:name)).to eq([ "rails" ])
    end
  end
end
