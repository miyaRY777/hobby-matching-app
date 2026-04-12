require "rails_helper"

RSpec.describe "Admin::HobbiesController", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  let!(:parent_tag) { create(:parent_tag, name: "アニメ", slug: "anime", room_type: :chat) }
  let!(:hobby) { create(:hobby, name: "進撃の巨人", parent_tag:) }

  describe "認可" do
    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get new_admin_hobby_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "非管理者の場合" do
      let!(:normal_user) { create(:user) }
      before { sign_in normal_user }

      it "root_path にリダイレクトされる" do
        get new_admin_hobby_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /admin/hobbies" do
    before { sign_in admin_user }

    it "子タグを作成して一覧へ戻る" do
      expect do
        post admin_hobbies_path, params: {
          hobby: { name: "ワンピース", parent_tag_id: parent_tag.id }
        }
      end.to change(Hobby, :count).by(1)

      expect(response).to redirect_to(admin_parent_tags_path)
    end
  end

  describe "PATCH /admin/hobbies/:id" do
    before { sign_in admin_user }

    it "子タグを更新して一覧へ戻る" do
      patch admin_hobby_path(hobby), params: {
        hobby: { name: "鬼滅の刃", parent_tag_id: parent_tag.id }
      }

      expect(hobby.reload.name).to eq("鬼滅の刃")
      expect(response).to redirect_to(admin_parent_tags_path)
    end
  end

  describe "DELETE /admin/hobbies/:id" do
    before { sign_in admin_user }

    it "未使用の子タグは削除できる" do
      deletable_hobby = create(:hobby, name: "ワンピース", parent_tag:)

      expect do
        delete admin_hobby_path(deletable_hobby)
      end.to change(Hobby, :count).by(-1)

      expect(response).to redirect_to(admin_parent_tags_path)
    end

    it "使用中の子タグは削除できず件数付きで一覧へ戻る" do
      create_list(:profile_hobby, 2, hobby:)

      expect do
        delete admin_hobby_path(hobby)
      end.not_to change(Hobby, :count)

      expect(response).to redirect_to(admin_parent_tags_path)
      follow_redirect!
      expect(response.body).to include("使用中のため削除できません（2件が使用中）")
    end
  end
end
