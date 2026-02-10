require "rails_helper"

RSpec.describe "Profile hobbies", type: :request do
  let(:user)    { create(:user) }
  let!(:profile) { create(:profile, user:) } # ← current_user の profile を明示

  before do
    sign_in user
  end

  describe "更新：PATCH /profile (my_profile_path)" do
    it "タグ入力を受け取り、hobbies を全置換して表示に反映される" do
      patch my_profile_path, params: {
        profile: { hobbies_text: "rails, ruby" }
      }

      expect(response).to redirect_to(profile_path(profile))
      follow_redirect!

      expect(response.body).to include("rails")
      expect(response.body).to include("ruby")
    end

    it "バリデーション失敗時に入力値を保持して再描画される" do
      patch my_profile_path, params: {
        profile: {
          bio: nil,
          hobbies_text: "rails, ruby"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("rails, ruby")
    end
  end

  describe "編集：GET /profile/edit (edit_my_profile_path)" do
    it "編集画面で既存の趣味がカンマ区切りで初期表示される" do
      rails = create(:hobby, name: "rails")
      ruby  = create(:hobby, name: "ruby")

      create(:profile_hobby, profile:, hobby: rails)
      create(:profile_hobby, profile:, hobby: ruby)

      get edit_my_profile_path

      expect(response.body).to include('value="rails,ruby"')
    end
  end
end

# frozen_string_literal: true まだ必要性がわかっていない
