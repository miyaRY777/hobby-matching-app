require "rails_helper"

RSpec.describe "Admin::HobbiesController", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  let!(:chat_tag) { create(:parent_tag, name: "アニメ", room_type: :chat) }
  let!(:study_tag) { create(:parent_tag, name: "プログラミング", room_type: :study) }
  let!(:hobby) do
    hobby = create(:hobby, name: "進撃の巨人")
    create(:hobby_parent_tag, hobby:, parent_tag: chat_tag)
    hobby
  end

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

    it "子タグを作成して hobby_parent_tag も作成し一覧へ戻る" do
      expect do
        post admin_hobbies_path, params: {
          hobby: { name: "ワンピース", chat_parent_tag_id: chat_tag.id }
        }
      end.to change(Hobby, :count).by(1)
        .and change(HobbyParentTag, :count).by(1)

      expect(response).to redirect_to(admin_parent_tags_path)
      new_hobby = Hobby.find_by(name: "ワンピース")
      expect(new_hobby.hobby_parent_tags.find_by(room_type: :chat)&.parent_tag).to eq(chat_tag)
    end

    it "chat_parent_tag_id が空でも hobby だけ作成される" do
      expect do
        post admin_hobbies_path, params: {
          hobby: { name: "ワンピース", chat_parent_tag_id: "" }
        }
      end.to change(Hobby, :count).by(1)

      new_hobby = Hobby.find_by(name: "ワンピース")
      expect(new_hobby.hobby_parent_tags).to be_empty
      expect(response).to redirect_to(admin_parent_tags_path)
    end
  end

  describe "PATCH /admin/hobbies/:id" do
    before { sign_in admin_user }

    it "子タグ名を更新して一覧へ戻る" do
      patch admin_hobby_path(hobby), params: {
        hobby: { name: "鬼滅の刃", chat_parent_tag_id: chat_tag.id }
      }

      expect(hobby.reload.name).to eq("鬼滅の刃")
      expect(response).to redirect_to(admin_parent_tags_path)
    end

    it "study_parent_tag_id を指定すると hobby_parent_tag が追加される" do
      patch admin_hobby_path(hobby), params: {
        hobby: { name: "進撃の巨人", study_parent_tag_id: study_tag.id }
      }

      expect(hobby.hobby_parent_tags.reload.find_by(room_type: :study)&.parent_tag).to eq(study_tag)
    end
  end

  describe "DELETE /admin/hobbies/:id" do
    before { sign_in admin_user }

    it "未使用の子タグは削除できる" do
      deletable_hobby = create(:hobby, name: "ワンピース")
      create(:hobby_parent_tag, hobby: deletable_hobby, parent_tag: chat_tag)

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
