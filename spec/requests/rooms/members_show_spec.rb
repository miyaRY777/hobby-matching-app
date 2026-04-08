require "rails_helper"

RSpec.describe "Rooms::Members#show", type: :request do
  # 部屋オーナーのセットアップ
  let(:room_owner_user) { create(:user, nickname: "issuer_nick") }
  let(:room_owner_profile) { create(:profile, user: room_owner_user) }
  let(:game_parent_tag) { create(:parent_tag, room_type: :game) }
  let(:room) { create(:room, issuer_profile: room_owner_profile, room_type: :game) }

  before do
    create(:room_membership, room: room, profile: room_owner_profile)
  end

  describe "認可" do
    it "未ログインのとき、ログインページにリダイレクトされる" do
      get room_member_path(room_id: room.id, id: room_owner_profile.id)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "ログイン済みでも部屋のメンバーでなければ403を返す" do
      # 部屋に参加していない別ユーザー
      other_user = create(:user)
      create(:profile, user: other_user)
      sign_in other_user

      get room_member_path(room_id: room.id, id: room_owner_profile.id)

      expect(response).to have_http_status(:forbidden)
    end

    it "部屋のメンバーであれば200を返す" do
      sign_in room_owner_user

      get room_member_path(room_id: room.id, id: room_owner_profile.id)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "@room_related_phs" do
    # 閲覧者（部屋メンバー）
    let!(:current_user) { create(:user) }
    let!(:current_profile) { create(:profile, user: current_user) }

    before do
      # 閲覧者を部屋に参加させる
      create(:room_membership, room: room, profile: current_profile)
      sign_in current_user
    end

    it "部屋のroom_typeに一致する親タグを持つ子タグを返す" do
      # game親タグに紐づく趣味をオーナープロフィールに追加
      game_hobby = create(:hobby, name: "マイクラ", parent_tag: game_parent_tag)
      room_owner_profile.hobbies << game_hobby

      get room_member_path(room_id: room.id, id: room_owner_profile.id)

      # game趣味が表示される
      expect(response.body).to include("マイクラ")
    end

    it "部屋のroom_typeと一致しない親タグの子タグは返さない" do
      # study親タグに紐づく趣味をオーナープロフィールに追加
      study_parent_tag = create(:parent_tag, room_type: :study)
      study_hobby = create(:hobby, name: "読書", parent_tag: study_parent_tag)
      room_owner_profile.hobbies << study_hobby

      get room_member_path(room_id: room.id, id: room_owner_profile.id)

      # study趣味は表示されない
      expect(response.body).not_to include("読書")
    end

    it "子タグが0件でも200を返す" do
      # 趣味を一切持たないオーナー
      get room_member_path(room_id: room.id, id: room_owner_profile.id)

      expect(response).to have_http_status(:ok)
    end
  end
end
