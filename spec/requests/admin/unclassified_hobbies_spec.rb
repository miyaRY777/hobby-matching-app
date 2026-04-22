require "rails_helper"

RSpec.describe "Admin::UnclassifiedHobbiesController", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  let!(:classified_parent_tag) { create(:parent_tag, room_type: :study) }

  let!(:unclassified_hobby) { create(:hobby, name: "rails") }
  let!(:classified_hobby) do
    hobby = create(:hobby, name: "Ruby")
    create(:hobby_parent_tag, hobby:, parent_tag: classified_parent_tag)
    hobby
  end

  describe "GET /admin/unclassified_hobbies" do
    context "管理者の場合" do
      before { sign_in admin_user }

      it "200 OK を返す" do
        get admin_unclassified_hobbies_path
        expect(response).to have_http_status(:ok)
      end

      it "未分類タグが名前列に含まれる" do
        get admin_unclassified_hobbies_path
        doc = Nokogiri::HTML(response.body)
        name_cells = doc.css("td[data-col='name']").map(&:text).map(&:strip)
        expect(name_cells).to include("rails")
      end

      it "分類済みタグは名前列に含まれない" do
        get admin_unclassified_hobbies_path
        doc = Nokogiri::HTML(response.body)
        name_cells = doc.css("td[data-col='name']").map(&:text).map(&:strip)
        expect(name_cells).not_to include("Ruby")
      end

      it "検索クエリに一致する未分類タグだけが名前列に含まれる" do
        create(:hobby, name: "python")

        get admin_unclassified_hobbies_path, params: { q: "rails" }
        doc = Nokogiri::HTML(response.body)
        name_cells = doc.css("td[data-col='name']").map(&:text).map(&:strip)
        expect(name_cells).to include("rails")
        expect(name_cells).not_to include("python")
      end

      context "usage_count / user_count の集計" do
        let!(:first_owner_profile) { create(:profile) }
        let!(:second_owner_profile) { create(:profile) }
        let!(:counted_hobby) { create(:hobby, name: "python") }

        before do
          create(:profile_hobby, profile: first_owner_profile, hobby: counted_hobby)
          create(:profile_hobby, profile: second_owner_profile, hobby: counted_hobby)
        end

        it "usage_count と user_count が 2 と集計されてレスポンスに含まれる" do
          get admin_unclassified_hobbies_path
          doc = Nokogiri::HTML(response.body)
          row = doc.at_css("[data-hobby-id='#{counted_hobby.id}']")
          expect(row.text).to include("2")
        end
      end
    end

    context "一般ユーザーの場合" do
      let!(:normal_user) { create(:user) }

      before { sign_in normal_user }

      it "root_path にリダイレクトされる" do
        get admin_unclassified_hobbies_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get admin_unclassified_hobbies_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /admin/unclassified_hobbies/:id" do
    context "管理者の場合" do
      before { sign_in admin_user }

      it "hobby_parent_tag が作成されて一覧にリダイレクトされる" do
        patch admin_unclassified_hobby_path(unclassified_hobby),
              params: { parent_tag_id: classified_parent_tag.id }

        aggregate_failures do
          hobby_parent_tag = unclassified_hobby.hobby_parent_tags.reload.find_by(room_type: classified_parent_tag.room_type)
          expect(hobby_parent_tag&.parent_tag).to eq(classified_parent_tag)
          expect(response).to redirect_to(admin_unclassified_hobbies_path)
        end
      end

      it "分類済み hobby を対象にすると 404 を返す" do
        patch admin_unclassified_hobby_path(classified_hobby),
              params: { parent_tag_id: classified_parent_tag.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "一般ユーザーの場合" do
      let!(:normal_user) { create(:user) }

      before { sign_in normal_user }

      it "root_path にリダイレクトされる" do
        patch admin_unclassified_hobby_path(unclassified_hobby),
              params: { parent_tag_id: classified_parent_tag.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /admin/unclassified_hobbies/:id" do
    context "管理者の場合" do
      before { sign_in admin_user }

      context "usage_count が 0 の場合" do
        it "削除されて一覧にリダイレクトされる" do
          delete admin_unclassified_hobby_path(unclassified_hobby)
          aggregate_failures do
            expect(Hobby.find_by(id: unclassified_hobby.id)).to be_nil
            expect(response).to redirect_to(admin_unclassified_hobbies_path)
          end
        end
      end

      context "usage_count が 1 以上の場合" do
        let!(:owner_profile) { create(:profile) }

        before { create(:profile_hobby, profile: owner_profile, hobby: unclassified_hobby) }

        it "削除されずに alert でリダイレクトされる" do
          delete admin_unclassified_hobby_path(unclassified_hobby)
          aggregate_failures do
            expect(Hobby.find_by(id: unclassified_hobby.id)).not_to be_nil
            expect(response).to redirect_to(admin_unclassified_hobbies_path)
          end
        end
      end

      context "分類済み hobby の場合" do
        it "404 を返す" do
          delete admin_unclassified_hobby_path(classified_hobby)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "一般ユーザーの場合" do
      let!(:normal_user) { create(:user) }

      before { sign_in normal_user }

      it "root_path にリダイレクトされる" do
        delete admin_unclassified_hobby_path(unclassified_hobby)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
