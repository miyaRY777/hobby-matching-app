require "rails_helper"

RSpec.describe "Admin::ParentTagsController", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  let!(:chat_parent_tag) { create(:parent_tag, name: "アニメ", slug: "anime", room_type: :chat, position: 1) }
  let!(:study_parent_tag) { create(:parent_tag, name: "資格", slug: "license", room_type: :study, position: 2) }
  let!(:uncategorized_parent_tag) { ParentTag.find_or_create_by!(slug: "uncategorized") { |pt| pt.name = "未分類" } }
  let!(:chat_hobby) { create(:hobby, name: "進撃の巨人", parent_tag: chat_parent_tag) }
  let!(:study_hobby) { create(:hobby, name: "簿記", parent_tag: study_parent_tag) }

  describe "GET /admin/parent_tags" do
    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get admin_parent_tags_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "非管理者の場合" do
      let!(:normal_user) { create(:user) }
      before { sign_in normal_user }

      it "root_path にリダイレクトされる" do
        get admin_parent_tags_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "管理者の場合" do
      before { sign_in admin_user }

      it "200 OK を返し、未分類親タグを除外して表示する" do
        get admin_parent_tags_path
        doc = Nokogiri::HTML(response.body)
        parent_tag_cells = doc.css("td[data-col='parent-tag']").map(&:text).map(&:strip)

        expect(response).to have_http_status(:ok)
        expect(parent_tag_cells).to include("アニメ", "資格")
        expect(parent_tag_cells).not_to include("未分類")
      end

      it "room_type で絞り込める" do
        get admin_parent_tags_path, params: { room_type: "chat" }
        doc = Nokogiri::HTML(response.body)
        parent_tag_cells = doc.css("td[data-col='parent-tag']").map(&:text).map(&:strip)

        expect(parent_tag_cells).to include("アニメ")
        expect(parent_tag_cells).not_to include("資格")
      end

      it "parent_tag_id で絞り込める" do
        get admin_parent_tags_path, params: { parent_tag_id: study_parent_tag.id }
        doc = Nokogiri::HTML(response.body)
        parent_tag_cells = doc.css("td[data-col='parent-tag']").map(&:text).map(&:strip)
        hobby_cells = doc.css("td[data-col='hobby-name']").map(&:text).map(&:strip)

        expect(parent_tag_cells).to include("資格")
        expect(hobby_cells).to include("簿記")
        expect(parent_tag_cells).not_to include("アニメ")
      end
    end
  end

  describe "POST /admin/parent_tags" do
    before { sign_in admin_user }

    it "親タグを作成して一覧へ戻る" do
      expect do
        post admin_parent_tags_path, params: {
          parent_tag: { name: "スポーツ", slug: "sports", room_type: "game" }
        }
      end.to change(ParentTag, :count).by(1)

      expect(response).to redirect_to(admin_parent_tags_path)
    end
  end

  describe "PATCH /admin/parent_tags/:id" do
    before { sign_in admin_user }

    it "親タグを更新して一覧へ戻る" do
      patch admin_parent_tag_path(chat_parent_tag), params: {
        parent_tag: { name: "マンガ", slug: "manga", room_type: "chat" }
      }

      expect(chat_parent_tag.reload.name).to eq("マンガ")
      expect(response).to redirect_to(admin_parent_tags_path)
    end
  end

  describe "DELETE /admin/parent_tags/:id" do
    before { sign_in admin_user }

    it "子タグがある場合は削除できず、件数付きで一覧へ戻る" do
      expect do
        delete admin_parent_tag_path(chat_parent_tag)
      end.not_to change(ParentTag, :count)

      expect(response).to redirect_to(admin_parent_tags_path)
      follow_redirect!
      expect(response.body).to include("子タグが1件あるため削除できません")
    end

    it "子タグがない場合は削除できる" do
      deletable_parent_tag = create(:parent_tag, name: "映画", slug: "movie", room_type: :chat)

      expect do
        delete admin_parent_tag_path(deletable_parent_tag)
      end.to change(ParentTag, :count).by(-1)

      expect(response).to redirect_to(admin_parent_tags_path)
    end
  end
end
