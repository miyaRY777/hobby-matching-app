require "rails_helper"

RSpec.describe Admin::HobbyMergeService do
  describe ".call" do
    let!(:source) { create(:hobby, name: "rails") }
    let!(:target) { create(:hobby, name: "Rails") }

    context "正常系: profile_hobbiesがない場合" do
      it "sourceが削除される" do
        described_class.call(source:, target:)
        expect(Hobby.find_by(id: source.id)).to be_nil
      end

      it "success?がtrueを返す" do
        result = described_class.call(source:, target:)
        expect(result.success?).to be true
      end
    end

    context "正常系: profile_hobbiesがある場合" do
      let!(:admin_profile) { create(:profile) }

      before { create(:profile_hobby, profile: admin_profile, hobby: source) }

      it "sourceのprofile_hobbiesがtargetに付け替えられる" do
        described_class.call(source:, target:)
        expect(ProfileHobby.where(hobby_id: target.id, profile_id: admin_profile.id)).to exist
      end

      it "sourceが削除される" do
        described_class.call(source:, target:)
        expect(Hobby.find_by(id: source.id)).to be_nil
      end
    end

    context "正常系: 重複するprofile_hobbiesがある場合" do
      let!(:admin_profile) { create(:profile) }

      before do
        # 同一プロフィールがsourceとtarget両方を持つ場合
        create(:profile_hobby, profile: admin_profile, hobby: source)
        create(:profile_hobby, profile: admin_profile, hobby: target)
      end

      it "重複するprofile_hobbiesが1件になる" do
        described_class.call(source:, target:)
        expect(ProfileHobby.where(profile_id: admin_profile.id, hobby_id: target.id).count).to eq 1
      end

      it "sourceが削除される" do
        described_class.call(source:, target:)
        expect(Hobby.find_by(id: source.id)).to be_nil
      end
    end

    context "異常系: 統合元と統合先が同じ場合" do
      it "success?がfalseを返す" do
        result = described_class.call(source:, target: source)
        expect(result.success?).to be false
      end

      it "errorメッセージを返す" do
        result = described_class.call(source:, target: source)
        expect(result.error).to eq "統合元と統合先が同じです"
      end

      it "sourceは削除されない" do
        described_class.call(source:, target: source)
        expect(Hobby.find_by(id: source.id)).to be_present
      end
    end
  end
end
