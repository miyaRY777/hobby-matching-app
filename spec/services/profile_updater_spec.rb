require "rails_helper"

RSpec.describe ProfileUpdater do
  describe ".call" do
    let(:profile) { create(:profile) }
    let(:hobbies_json) { [ { name: "ゲーム", description: "" } ].to_json }
    let(:profile_params) { { bio: "更新後", hobbies_json: hobbies_json } }

    subject(:result) { described_class.call(profile: profile, profile_params: profile_params) }

    it "bio を更新し趣味を同期する" do
      result

      expect(result[:success]).to be true
      expect(profile.reload.bio).to eq("更新後")
      expect(profile.hobbies.pluck(:name)).to include("ゲーム")
    end

    context "hobbies_json が空のとき" do
      let(:existing_hobby) { create(:hobby, name: "既存趣味") }
      let(:profile_params) { { bio: "bioのみ更新", hobbies_json: "" } }

      before { create(:profile_hobby, profile: profile, hobby: existing_hobby) }

      it "bio のみ更新し既存趣味を残す" do
        result

        expect(result[:success]).to be true
        expect(profile.reload.bio).to eq("bioのみ更新")
        expect(profile.hobbies.pluck(:name)).to include("既存趣味")
      end
    end

    context "bio が空のとき" do
      let(:profile_params) { { bio: "", hobbies_json: hobbies_json } }

      it "失敗しロールバックする" do
        original_bio = profile.bio

        expect(result[:success]).to be false
        expect(profile.reload.bio).to eq(original_bio)
        expect(result[:profile].errors[:bio]).to be_present
      end
    end
  end
end
