require "rails_helper"

RSpec.describe "Login guard", type: :request do
  it "未ログインでmy_profile/editに行くとログインへリダイレクトしメッセージが出る" do
    get edit_my_profile_path

    expect(response).to redirect_to(new_user_session_path)
    follow_redirect!

    expect(response.body).to include("ログインまたは新規登録してください。")
  end

  it "ログイン後に元のページへ戻れる" do
    user = create(:user)
    profile = create(:profile, user:)

    get edit_my_profile_path
    expect(response).to redirect_to(new_user_session_path)

    post user_session_path, params:{
      user: { email: user.email, password: user.password}
    }

    # 元のページへリダイレクトされることを確認
    expect(response).to redirect_to(edit_my_profile_path)

    follow_redirect!
    expect(response).to have_http_status(:ok)
  end
end