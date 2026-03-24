require "rails_helper"

RSpec.describe ContactMailer, type: :mailer do
  describe "#notify" do
    let(:form) do
      ContactForm.new(name: "テスト太郎", email: "test@example.com", subject: "テスト件名", body: "お問い合わせ内容です。")
    end
    let(:mail) { described_class.notify(form) }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CONTACT_EMAIL", anything).and_return("admin@example.com")
    end

    it "CONTACT_EMAIL宛に送信される" do
      expect(mail.to).to eq([ "admin@example.com" ])
    end

    it "件名にフォームの件名が含まれる" do
      expect(mail.subject).to include("テスト件名")
    end

    it "本文に名前が含まれる" do
      text_body = mail.text_part.body.decoded
      expect(text_body).to include("テスト太郎")
    end

    it "本文にメールアドレスが含まれる" do
      text_body = mail.text_part.body.decoded
      expect(text_body).to include("test@example.com")
    end

    it "本文にお問い合わせ内容が含まれる" do
      text_body = mail.text_part.body.decoded
      expect(text_body).to include("お問い合わせ内容です。")
    end
  end
end
