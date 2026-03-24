require "rails_helper"

RSpec.describe ContactForm, type: :model do
  let(:valid_params) do
    { name: "テスト太郎", email: "test@example.com", subject: "テスト件名", body: "お問い合わせ内容です。" }
  end

  describe "バリデーション" do
    it "全項目入力でvalid" do
      form = described_class.new(valid_params)
      expect(form).to be_valid
    end

    it "名前が未入力でinvalid" do
      form = described_class.new(valid_params.merge(name: ""))
      expect(form).to be_invalid
    end

    it "メールアドレスが未入力でinvalid" do
      form = described_class.new(valid_params.merge(email: ""))
      expect(form).to be_invalid
    end

    it "メールアドレスが形式不正でinvalid" do
      form = described_class.new(valid_params.merge(email: "invalid"))
      expect(form).to be_invalid
    end

    it "件名が未入力でinvalid" do
      form = described_class.new(valid_params.merge(subject: ""))
      expect(form).to be_invalid
    end

    it "本文が未入力でinvalid" do
      form = described_class.new(valid_params.merge(body: ""))
      expect(form).to be_invalid
    end
  end
end
