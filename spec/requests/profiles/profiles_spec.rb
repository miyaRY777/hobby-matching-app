require "rails_helper"

RSpec.describe "Profiles", type: :request do
  describe "GET /profiles" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    # タグ関連のテスト
    it "profiles一覧でタグが表示される" do
      profile = create(:profile)
      rails = create(:hobby, name: "rails")
      create(:profile_hobby, profile:, hobby: rails)

      get profiles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("rails")
    end

    it "一覧で趣味が0件の場合、未登録が表示される" do
      create(:profile)

      get profiles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("未登録")
    end

    context "検索クエリがある場合" do
      let(:target_user) { create(:user, nickname: "たろう") }
      let(:other_user)  { create(:user, nickname: "はなこ") }
      let(:target_profile) { create(:profile, user: target_user) }
      let(:other_profile)  { create(:profile, user: other_user) }
      let(:hobby_game) { create(:hobby, name: "ゲーム") }

      before do
        create(:profile_hobby, profile: target_profile, hobby: hobby_game)
      end

      it "趣味タグで絞り込まれた一覧が返る" do
        get profiles_path, params: { q: "ゲーム", mode: "and" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("たろう")
        expect(response.body).not_to include("はなこ")
      end

      it "nicknameで絞り込まれた一覧が返る" do
        get profiles_path, params: { q: "たろう", mode: "and" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("たろう")
        expect(response.body).not_to include("はなこ")
      end
    end
  end
end
