require "rails_helper"

RSpec.describe "Profiles#show authentication", type: :request do
  it "未ログインでprofiles/:idにアクセスすると、ログインページにリダイレクトする" do
    profile = create(:profile)

    get profile_path(profile)
    expect(response).to redirect_to(new_user_session_path)

  end
end