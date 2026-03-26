require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#avatar_image_tag" do
    context "アバターが未設定の場合" do
      let(:user) { create(:user) }

      it "デフォルトアイコンのimgタグを返す" do
        result = helper.avatar_image_tag(user)

        expect(result).to include("<img")
        expect(result).to include("svg")
        expect(result).to include('data-testid="avatar"')
      end
    end

    context "アバターが設定されている場合" do
      let(:user) { create(:user) }

      before do
        user.avatar.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/valid_avatar.jpg")),
          filename: "avatar.jpg",
          content_type: "image/jpeg"
        )
      end

      it "アバター画像のimgタグを返す" do
        result = helper.avatar_image_tag(user)

        expect(result).to include("<img")
        expect(result).not_to include("svg")
        expect(result).to include('data-testid="avatar"')
      end
    end
  end
end
