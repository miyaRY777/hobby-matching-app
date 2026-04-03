require "rails_helper"

RSpec.describe "Profile hobbies", type: :request do
  let(:user)    { create(:user) }
  let!(:profile) { create(:profile, user:) } # ← current_user の profile を明示
  let!(:uncategorized) { ParentTag.find_or_create_by!(slug: "uncategorized", room_type: nil) { |pt| pt.name = "未分類"; pt.position = 0 } }

  before do
    sign_in user
  end

  describe "更新：PATCH /profile (my_profile_path)" do
    it "タグ入力を受け取り、hobbies を全置換して表示に反映される" do
      hobbies_text = [ { name: "rails", description: "" }, { name: "ruby", description: "" } ].to_json

      patch my_profile_path, params: {
        profile: { hobbies_text: }
      }

      expect(response).to redirect_to(profile_path(profile))
      follow_redirect!

      expect(response.body).to include("rails")
      expect(response.body).to include("ruby")
    end

    it "バリデーション失敗時（タグ上限超過）に再描画される" do
      eleven_tags = (1..11).map { |i| { name: "tag#{i}", description: "" } }.to_json

      patch my_profile_path, params: {
        profile: { hobbies_text: eleven_tags }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "編集：GET /profile/edit (edit_my_profile_path)" do
    it "編集画面で既存の趣味がJSON形式でhidden fieldに初期表示される" do
      rails_hobby = create(:hobby, name: "rails")
      ruby_hobby  = create(:hobby, name: "ruby")

      create(:profile_hobby, profile:, hobby: rails_hobby)
      create(:profile_hobby, profile:, hobby: ruby_hobby)

      get edit_my_profile_path

      expect(response.body).to include("&quot;name&quot;:&quot;rails&quot;")
      expect(response.body).to include("&quot;name&quot;:&quot;ruby&quot;")
    end
  end
end
