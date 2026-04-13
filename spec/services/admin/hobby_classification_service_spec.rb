require "rails_helper"

RSpec.describe Admin::HobbyClassificationService do
  describe ".call" do
    let(:hobby) { create(:hobby) }
    let(:chat_tag) { create(:parent_tag, room_type: :chat) }
    let(:chat_tag2) { create(:parent_tag, room_type: :chat) }
    let(:game_tag) { create(:parent_tag, room_type: :game) }

    context "新規分類（該当 room_type の hobby_parent_tag がない）" do
      it "hobby_parent_tag を 1 件作成する" do
        expect do
          described_class.call(hobby:, parent_tag: chat_tag)
        end.to change(HobbyParentTag, :count).by(1)
      end

      it "指定した parent_tag が設定される" do
        described_class.call(hobby:, parent_tag: chat_tag)

        hobby_parent_tag = hobby.hobby_parent_tags.find_by(room_type: :chat)
        expect(hobby_parent_tag.parent_tag).to eq(chat_tag)
      end
    end

    context "同 room_type の上書き（既存の hobby_parent_tag がある）" do
      before { create(:hobby_parent_tag, hobby:, parent_tag: chat_tag) }

      it "hobby_parent_tag を新規作成しない" do
        expect do
          described_class.call(hobby:, parent_tag: chat_tag2)
        end.not_to change(HobbyParentTag, :count)
      end

      it "parent_tag を新しい値に更新する" do
        described_class.call(hobby:, parent_tag: chat_tag2)

        expect(hobby.hobby_parent_tags.find_by(room_type: :chat).parent_tag).to eq(chat_tag2)
      end
    end

    context "異なる room_type への追加分類" do
      before { create(:hobby_parent_tag, hobby:, parent_tag: chat_tag) }

      it "hobby_parent_tag を追加で 1 件作成する" do
        expect do
          described_class.call(hobby:, parent_tag: game_tag)
        end.to change(HobbyParentTag, :count).by(1)
      end
    end
  end
end
