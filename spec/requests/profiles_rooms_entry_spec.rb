require "rails_helper"

RSpec.describe "Profiles", type: :request do
  it "共有リンク管理へのリンクを表示する" do
    user = create(:user)
    create(:profile, user: user)

    sign_in user
    get profiles_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("共有リンク管理")
    expect(response.body).to include(my_rooms_path)
  end
end
