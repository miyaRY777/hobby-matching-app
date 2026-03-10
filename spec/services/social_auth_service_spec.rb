require "rails_helper"

RSpec.describe SocialAuthService, type: :service do
  let(:auth) do
    OmniAuth::AuthHash.new(
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

  describe ".call" do
    context "when SocialAccount already exists for provider + uid" do
      it "returns the existing user" do
        user = create(:user)
        create(:social_account, user: user, provider: "google_oauth2", uid: "123456")

        result = described_class.call(auth)

        expect(result).to be_success
        expect(result.user).to eq(user)
      end

      it "does not create a new User or SocialAccount" do
        user = create(:user)
        create(:social_account, user: user, provider: "google_oauth2", uid: "123456")

        expect { described_class.call(auth) }
          .to change(User, :count).by(0)
          .and change(SocialAccount, :count).by(0)
      end
    end

    context "when SocialAccount does not exist but same email user exists" do
      it "links SocialAccount to existing user" do
        existing_user = create(:user, email: "oauth@example.com")

        result = described_class.call(auth)

        expect(result).to be_success
        expect(result.user).to eq(existing_user)
        expect(existing_user.social_accounts.find_by(provider: "google_oauth2", uid: "123456")).to be_present
      end

      it "creates a SocialAccount but not a User" do
        create(:user, email: "oauth@example.com")

        expect { described_class.call(auth) }
          .to change(User, :count).by(0)
          .and change(SocialAccount, :count).by(1)
      end
    end

    context "when neither SocialAccount nor same email user exists" do
      it "creates a new User and SocialAccount" do
        result = described_class.call(auth)

        expect(result).to be_success
        expect(result.user).to be_persisted
        expect(result.user.email).to eq("oauth@example.com")
        expect(result.user.social_accounts.find_by(provider: "google_oauth2", uid: "123456")).to be_present
      end

      it "increments User and SocialAccount counts" do
        expect { described_class.call(auth) }
          .to change(User, :count).by(1)
          .and change(SocialAccount, :count).by(1)
      end
    end

    context "nickname handling" do
      it "sets auth.info.name as nickname" do
        result = described_class.call(auth)

        expect(result.user.nickname).to eq("Google User")
      end

      it "truncates nickname longer than 20 characters" do
        auth.info.name = "A" * 25

        result = described_class.call(auth)

        expect(result.user.nickname).to eq("A" * 20)
      end

      it "sets fallback nickname when name is blank" do
        auth.info.name = ""

        result = described_class.call(auth)

        expect(result.user.nickname).to be_present
        expect(result.user.nickname.length).to be <= 20
      end

      it "sets fallback nickname when name is nil" do
        auth.info.name = nil

        result = described_class.call(auth)

        expect(result.user.nickname).to be_present
      end
    end

    context "when email is missing" do
      it "returns failure result" do
        auth.info.email = nil

        result = described_class.call(auth)

        expect(result).not_to be_success
        expect(result.error_message).to be_present
      end

      it "returns failure when email is empty string" do
        auth.info.email = ""

        result = described_class.call(auth)

        expect(result).not_to be_success
      end
    end

    context "when email_verified is not true" do
      it "returns failure when email_verified is false in id_info" do
        auth.extra.id_info.email_verified = false

        result = described_class.call(auth)

        expect(result).not_to be_success
        expect(result.error_message).to be_present
      end

      it "falls back to raw_info when id_info is not available" do
        auth.extra = { raw_info: { email_verified: "true" } }

        result = described_class.call(auth)

        expect(result).to be_success
      end

      it "returns failure when raw_info email_verified is false string" do
        auth.extra = { raw_info: { email_verified: "false" } }

        result = described_class.call(auth)

        expect(result).not_to be_success
      end
    end

    context "when RecordNotUnique is raised (race condition)" do
      it "retries and returns the existing SocialAccount user" do
        user = create(:user, email: "oauth@example.com")

        first_call = true
        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy).to receive(:create!).and_wrap_original do |method, **args|
          if first_call
            first_call = false
            create(:social_account, user: user, provider: "google_oauth2", uid: "123456")
            raise ActiveRecord::RecordNotUnique
          end
          method.call(**args)
        end

        result = described_class.call(auth)

        expect(result).to be_success
        expect(result.user).to eq(user)
      end
    end
  end
end
