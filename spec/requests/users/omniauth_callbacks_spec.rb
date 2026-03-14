require "rails_helper"

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  before do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "123456",
      info: {
        email: "oauth@example.com",
        name: "Google User"
      },
      extra: {
        id_info: {
          email_verified: true
        }
      }
    )
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  describe "GET /users/auth/google_oauth2/callback" do
    context "when authentication succeeds" do
      it "signs in and redirects" do
        get "/users/auth/google_oauth2/callback"

        expect(response).to redirect_to(profiles_path)
        expect(controller.current_user).to be_present
      end

      it "creates a new user for first-time OAuth login" do
        expect { get "/users/auth/google_oauth2/callback" }
          .to change(User, :count).by(1)
          .and change(SocialAccount, :count).by(1)
      end

      it "does not create a new user when SocialAccount already exists" do
        user = create(:user)
        create(:social_account, user: user, provider: "google_oauth2", uid: "123456")

        expect { get "/users/auth/google_oauth2/callback" }
          .to change(User, :count).by(0)
          .and change(SocialAccount, :count).by(0)
      end
    end

    context "when email is missing" do
      before do
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          uid: "123456",
          info: { email: nil, name: "Google User" },
          extra: { id_info: { email_verified: true } }
        )
      end

      it "redirects to sign in page with error message" do
        get "/users/auth/google_oauth2/callback"

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when email_verified is false" do
      before do
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          uid: "123456",
          info: { email: "oauth@example.com", name: "Google User" },
          extra: { id_info: { email_verified: false } }
        )
      end

      it "redirects to sign in page with error message" do
        get "/users/auth/google_oauth2/callback"

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "GET /users/auth/discord/callback" do
    before do
      OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
        provider: "discord",
        uid: "discord_789",
        info: {
          email: "discord@example.com",
          name: "DiscordUser"
        },
        extra: {
          raw_info: { verified: true }
        }
      )
    end

    after do
      OmniAuth.config.mock_auth[:discord] = nil
    end

    context "when authentication succeeds" do
      it "signs in and redirects" do
        get "/users/auth/discord/callback"

        expect(response).to redirect_to(profiles_path)
        expect(controller.current_user).to be_present
      end

      it "creates a new user for first-time OAuth login" do
        expect { get "/users/auth/discord/callback" }
          .to change(User, :count).by(1)
          .and change(SocialAccount, :count).by(1)
      end
    end

    context "when email is not verified" do
      before do
        OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
          provider: "discord",
          uid: "discord_789",
          info: { email: "discord@example.com", name: "DiscordUser" },
          extra: { raw_info: { verified: false } }
        )
      end

      it "redirects to sign in page with error message" do
        get "/users/auth/discord/callback"

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
