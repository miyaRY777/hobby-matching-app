require "rails_helper"

RSpec.describe "Profiles#show shared hobbies", type: :request do
  it "ログイン済みで他人プロフィール詳細を聞くと、共通hobbiesが表示される" do

    # ログインユーザー
    my_user = create(:user)
    my_profile = create(:profile, user: my_user)

    # 相手ユーザー
    other_user = create(:user)
    other_profile = create(:profile, user: other_user)

    # 共通Hobby
    rails = create(:hobby, name: "rails")
    create(:profile_hobby, profile: my_profile, hobby: rails)
    create(:profile_hobby, profile: other_profile, hobby: rails)

    sign_in my_user

    get profile_path(other_profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("共通の趣味")
    expect(response.body).to include("rails")
  end
end