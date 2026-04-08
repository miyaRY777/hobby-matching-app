require "rails_helper"

RSpec.describe JsmindDataBuilder do
  # 部屋タイプ: chat
  let(:chat_parent_tag)  { create(:parent_tag, name: "アニメ",        room_type: :chat,  position: 1) }
  let(:chat_parent_tag2) { create(:parent_tag, name: "ゲーム",        room_type: :chat,  position: 2) }
  let(:study_parent_tag) { create(:parent_tag, name: "プログラミング", room_type: :study, position: 1) }

  let(:hobby_anime) { create(:hobby, name: "ワンピース", parent_tag: chat_parent_tag) }
  let(:hobby_game)  { create(:hobby, name: "マイクラ",  parent_tag: chat_parent_tag2) }
  let(:hobby_prog)  { create(:hobby, name: "Rails",    parent_tag: study_parent_tag) }

  let(:chat_room) { create(:room, room_type: :chat) }

  let(:current_user)    { create(:user, nickname: "user1") }
  let(:current_profile) { create(:profile, user: current_user) }

  # memberships は before ブロックで membership を作成してから評価する
  let(:memberships) do
    chat_room.room_memberships
             .includes(profile: [ :user, { profile_hobbies: { hobby: :parent_tag } } ])
  end

  subject(:result) { described_class.new(chat_room, memberships).build }

  describe "#build" do
    before { create(:room_membership, room: chat_room, profile: current_profile) }

    it "node_tree フォーマットを返す" do
      expect(result[:format]).to eq "node_tree"
    end

    it "ルートノードの topic に部屋名が設定される" do
      expect(result[:data][:topic]).to eq chat_room.label
    end

    context "部屋タイプに一致する趣味を持つユーザーがいる場合" do
      before { current_profile.hobbies << hobby_anime }

      it "親タグノードが children に含まれる" do
        expect(result[:data][:children].map { |n| n[:topic] }).to include("アニメ")
      end

      it "ユーザーが親タグノードの children に含まれる" do
        anime_node = result[:data][:children].find { |n| n[:topic] == "アニメ" }
        expect(anime_node[:children].map { |n| n[:topic] }).to include("user1")
      end

      it "ユーザーノードの URL に /rooms/:room_id/members/:id が設定される" do
        anime_node = result[:data][:children].find { |n| n[:topic] == "アニメ" }
        user_node  = anime_node[:children].find { |n| n[:topic] == "user1" }
        expect(user_node[:data][:url]).to eq "/rooms/#{chat_room.id}/members/#{current_profile.id}"
      end

      it "「その他」ノードが表示されない" do
        expect(result[:data][:children].map { |n| n[:topic] }).not_to include("その他")
      end
    end

    context "複数の親タグに趣味を持つユーザーがいる場合" do
      before do
        # chat_parent_tag（アニメ）と chat_parent_tag2（ゲーム）両方に趣味を持つ
        current_profile.hobbies << hobby_anime
        current_profile.hobbies << hobby_game
      end

      it "複数の親タグノードにユーザーが重複表示される" do
        nodes_with_user = result[:data][:children].select do |n|
          n[:children]&.any? { |u| u[:topic] == "user1" }
        end
        expect(nodes_with_user.size).to eq 2
      end

      it "「その他」ノードが表示されない" do
        expect(result[:data][:children].map { |n| n[:topic] }).not_to include("その他")
      end
    end

    context "部屋タイプに一致しない趣味しか持たないユーザーがいる場合" do
      before { current_profile.hobbies << hobby_prog }

      it "「その他」ノードが children に含まれる" do
        expect(result[:data][:children].map { |n| n[:topic] }).to include("その他")
      end

      it "「その他」ノードは expanded: false" do
        other_node = result[:data][:children].find { |n| n[:topic] == "その他" }
        expect(other_node[:expanded]).to eq false
      end

      it "ユーザーが「その他」ノードの children に含まれる" do
        other_node = result[:data][:children].find { |n| n[:topic] == "その他" }
        expect(other_node[:children].map { |n| n[:topic] }).to include("user1")
      end
    end

    context "趣味未登録のユーザーがいる場合" do
      # 趣味なし（before ブロックに追記なし）

      it "「その他」ノードに表示される" do
        other_node = result[:data][:children].find { |n| n[:topic] == "その他" }
        expect(other_node[:children].map { |n| n[:topic] }).to include("user1")
      end
    end

    context "対象ユーザーが0人の親タグがある場合" do
      before do
        # chat_parent_tag（アニメ）のみ持つ → chat_parent_tag2（ゲーム）は0人
        current_profile.hobbies << hobby_anime
        chat_parent_tag2 # 事前生成して DB に存在させる
      end

      it "対象ユーザーが0人の親タグノードは表示されない" do
        expect(result[:data][:children].map { |n| n[:topic] }).not_to include("ゲーム")
      end
    end
  end
end
