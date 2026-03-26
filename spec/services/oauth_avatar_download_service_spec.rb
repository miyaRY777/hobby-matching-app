require "rails_helper"

RSpec.describe OauthAvatarDownloadService, type: :service do
  let(:user) { create(:user) }

  describe ".call" do
    context "with Google OAuth" do
      let(:auth) do
        OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          info: { image: "https://lh3.googleusercontent.com/photo.jpg" }
        )
      end

      it "downloads and attaches avatar to user" do
        stub_request(:get, "https://lh3.googleusercontent.com/photo.jpg")
          .to_return(status: 200, body: file_fixture("valid_avatar.jpg").read, headers: { "Content-Type" => "image/jpeg" })

        described_class.call(user: user, auth: auth)

        expect(user.avatar).to be_attached
      end
    end

    context "with Discord OAuth" do
      let(:auth) do
        OmniAuth::AuthHash.new(
          provider: "discord",
          uid: "123456789",
          info: { image: "https://cdn.discordapp.com/avatars/123456789/abc123.png" }
        )
      end

      it "downloads and attaches avatar to user" do
        stub_request(:get, "https://cdn.discordapp.com/avatars/123456789/abc123.png")
          .to_return(status: 200, body: file_fixture("valid_avatar.jpg").read, headers: { "Content-Type" => "image/png" })

        described_class.call(user: user, auth: auth)

        expect(user.avatar).to be_attached
      end
    end

    context "when user already has an avatar" do
      it "does not overwrite the existing avatar" do
        user.avatar.attach(io: file_fixture("valid_avatar.jpg").open, filename: "existing.jpg", content_type: "image/jpeg")

        auth = OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          info: { image: "https://example.com/photo.jpg" }
        )

        described_class.call(user: user, auth: auth)

        expect(user.avatar.filename.to_s).to eq("existing.jpg")
      end
    end

    context "when image URL is blank" do
      it "does nothing and does not raise" do
        auth = OmniAuth::AuthHash.new(provider: "google_oauth2", info: { image: nil })

        expect { described_class.call(user: user, auth: auth) }.not_to raise_error
        expect(user.avatar).not_to be_attached
      end
    end

    context "when download fails" do
      it "does not raise and leaves avatar unattached" do
        auth = OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          info: { image: "https://example.com/broken.jpg" }
        )

        stub_request(:get, "https://example.com/broken.jpg").to_return(status: 500)

        expect { described_class.call(user: user, auth: auth) }.not_to raise_error
        expect(user.avatar).not_to be_attached
      end
    end
  end
end
