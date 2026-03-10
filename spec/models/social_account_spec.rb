require "rails_helper"

RSpec.describe SocialAccount, type: :model do
  describe "associations" do
    it "belongs to user" do
      social_account = build(:social_account)
      expect(social_account).to respond_to(:user)
      expect(social_account.user).to be_a(User)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      social_account = build(:social_account)
      expect(social_account).to be_valid
    end

    it "is invalid without provider" do
      social_account = build(:social_account, provider: nil)
      expect(social_account).not_to be_valid
      expect(social_account.errors[:provider]).to be_present
    end

    it "is invalid without uid" do
      social_account = build(:social_account, uid: nil)
      expect(social_account).not_to be_valid
      expect(social_account.errors[:uid]).to be_present
    end

    it "is invalid with duplicate provider and uid" do
      create(:social_account, provider: "google_oauth2", uid: "same_uid")
      duplicate = build(:social_account, provider: "google_oauth2", uid: "same_uid")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uid]).to be_present
    end

    it "is invalid with duplicate user_id and provider" do
      user = create(:user)
      create(:social_account, user: user, provider: "google_oauth2")
      duplicate = build(:social_account, user: user, provider: "google_oauth2")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:provider]).to be_present
    end

    it "allows same provider with different uids" do
      create(:social_account, provider: "google_oauth2", uid: "uid_1")
      other = build(:social_account, provider: "google_oauth2", uid: "uid_2")
      expect(other).to be_valid
    end

    it "allows same user with different providers" do
      user = create(:user)
      create(:social_account, user: user, provider: "google_oauth2")
      other = build(:social_account, user: user, provider: "discord")
      expect(other).to be_valid
    end
  end

  describe "user association" do
    it "user has_many social_accounts" do
      user = create(:user)
      create(:social_account, user: user, provider: "google_oauth2")
      create(:social_account, user: user, provider: "discord", uid: "discord_uid")
      expect(user.social_accounts.count).to eq(2)
    end
  end
end
