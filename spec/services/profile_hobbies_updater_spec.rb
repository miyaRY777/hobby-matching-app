require "rails_helper"

RSpec.describe ProfileHobbiesUpdater do
  describe ".call" do
    let(:profile) { create(:profile) }

    it "新規タグを追加しdescriptionを保存する" do
      described_class.call(profile, [ { name: "ruby", description: "3年やってます" } ])

      ph = profile.profile_hobbies.joins(:hobby).find_by(hobbies: { name: "ruby" })
      expect(ph).not_to be_nil
      expect(ph.description).to eq("3年やってます")
    end

    it "既存タグのdescriptionを更新する" do
      hobby = create(:hobby, name: "ruby")
      create(:profile_hobby, profile:, hobby:, description: "古い説明")

      described_class.call(profile, [ { name: "ruby", description: "新しい説明" } ])

      ph = profile.profile_hobbies.joins(:hobby).find_by(hobbies: { name: "ruby" })
      expect(ph.description).to eq("新しい説明")
    end

    it "削除されたタグのprofile_hobbyを削除する" do
      hobby = create(:hobby, name: "rails")
      create(:profile_hobby, profile:, hobby:)

      described_class.call(profile, [ { name: "ruby", description: "" } ])

      expect(profile.hobbies.pluck(:name)).to match_array([ "ruby" ])
    end

    it "既存Hobbyを再利用する（Hobby件数が増えない）" do
      create(:hobby, name: "ruby")

      expect { described_class.call(profile, [ { name: "ruby", description: "" } ]) }
        .not_to change(Hobby, :count)
    end

    it "タグ名をdowncaseで正規化して保存する" do
      described_class.call(profile, [ { name: "Ruby", description: "" } ])

      expect(profile.hobbies.pluck(:name)).to include("ruby")
    end

    it "重複タグは1件のみ保存する" do
      described_class.call(profile, [
        { name: "ruby", description: "最初" },
        { name: "ruby", description: "2回目" }
      ])

      expect(profile.profile_hobbies.joins(:hobby).where(hobbies: { name: "ruby" }).count).to eq(1)
    end

    it "空のタグデータで全削除される" do
      hobby = create(:hobby, name: "ruby")
      create(:profile_hobby, profile:, hobby:)

      described_class.call(profile, [])

      expect(profile.hobbies).to be_empty
    end
  end
end
