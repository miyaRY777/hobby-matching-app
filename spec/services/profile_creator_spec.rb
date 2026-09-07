require "rails_helper"

RSpec.describe ProfileCreator do
  describe ".call" do
    let(:user) { create(:user) }
    let(:hobbies_json) { [ { name: "ゲーム", description: "" } ].to_json }
    let(:profile_params) { { bio: "自己紹介", hobbies_json: hobbies_json } }

    subject(:result) { described_class.call(user: user, profile_params: profile_params) }

    it "Profile と ProfileHobby を作成する" do
      expect { result }
        .to change(Profile, :count).by(1)
        .and change(ProfileHobby, :count).by(1)

      expect(result[:success]).to be true
      expect(result[:profile]).to be_persisted
      expect(result[:profile].hobbies.pluck(:name)).to include("ゲーム")
    end

    context "bio が空のとき" do
      let(:profile_params) { { bio: "", hobbies_json: hobbies_json } }

      it "失敗しレコードを増やさない" do
        expect { result }.not_to change(Profile, :count)
        expect(ProfileHobby.count).to eq(0)
        expect(result[:success]).to be false
        expect(result[:profile]).not_to be_persisted
        expect(result[:profile].errors[:bio]).to be_present
      end
    end

    context "タグが 0 個のとき" do
      let(:hobbies_json) { [].to_json }

      it "失敗しレコードを増やさない" do
        expect { result }.not_to change(Profile, :count)
        expect(result[:success]).to be false
        expect(result[:profile].errors[:hobbies_json]).to be_present
      end
    end
  end
end
