require "rails_helper"

RSpec.describe Devise::Mailer, type: :mailer do
  describe "reset_password_instructions" do
    let(:user) { create(:user) }
    let(:token) { "test-reset-token" }
    let(:mail) { Devise::Mailer.reset_password_instructions(user, token) }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MAILER_FROM", anything).and_return("noreply@example.com")
    end

    it "送信元がMAILER_FROMになる" do
      expect(mail.from).to include("noreply@example.com")
    end

    it "本文に日本語の案内が含まれる" do
      expect(mail.body.decoded).to include("パスワード再設定")
    end

    it "本文に「パスワードを変更する」リンクテキストが含まれる" do
      expect(mail.body.decoded).to include("パスワードを変更する")
    end
  end
end
