# frozen_string_literal: true

require "rails_helper"

RSpec.describe Profile, type: :model do
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
