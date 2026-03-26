require "rails_helper"

RSpec.describe User, type: :model do
  describe "avatar バリデーション" do
    let(:user) { create(:user) }

    context "許可されるファイル形式" do
      %w[image/jpeg image/png image/gif image/webp].each do |content_type|
        it "#{content_type} は有効" do
          user.avatar.attach(
            io: StringIO.new("dummy"),
            filename: "avatar.#{content_type.split('/').last}",
            content_type: content_type
          )
          expect(user).to be_valid
        end
      end
    end

    context "許可されないファイル形式" do
      it "BMP は無効" do
        user.avatar.attach(
          io: StringIO.new("dummy"),
          filename: "avatar.bmp",
          content_type: "image/bmp"
        )
        expect(user).not_to be_valid
        expect(user.errors[:avatar]).to be_present
      end
    end

    context "ファイルサイズ" do
      it "5MB以下は有効" do
        user.avatar.attach(
          io: StringIO.new("a" * 5.megabytes),
          filename: "avatar.jpg",
          content_type: "image/jpeg"
        )
        expect(user).to be_valid
      end

      it "5MB超は無効" do
        user.avatar.attach(
          io: StringIO.new("a" * (5.megabytes + 1)),
          filename: "avatar.jpg",
          content_type: "image/jpeg"
        )
        expect(user).not_to be_valid
        expect(user.errors[:avatar]).to be_present
      end
    end
  end
end
