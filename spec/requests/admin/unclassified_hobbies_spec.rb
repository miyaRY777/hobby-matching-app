require "rails_helper"

RSpec.describe "Admin::UnclassifiedHobbiesController", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  # Hobby.unclassified は slug: "uncategorized" の親タグに依存するため find_or_create_by! を使う
  let!(:uncategorized_parent_tag) do
    ParentTag.find_or_create_by!(slug: "uncategorized", room_type: nil) { |pt| pt.name = "未分類" }
  end
  let!(:classified_parent_tag)    { create(:parent_tag) }

  # -----------------------------------------------------------------------
  # GET /admin/unclassified_hobbies
  # -----------------------------------------------------------------------
  describe "GET /admin/unclassified_hobbies" do
    let!(:unclassified_hobby) { create(:hobby, name: "rails",  parent_tag: uncategorized_parent_tag) }
    let!(:classified_hobby)   { create(:hobby, name: "Ruby",   parent_tag: classified_parent_tag) }

    context "管理者の場合" do
      before { sign_in admin_user }

      it "200 OK を返す" do
        # 管理者がアクセスする
        get admin_unclassified_hobbies_path
        expect(response).to have_http_status(:ok)
      end

      it "未分類タグが名前列に含まれる" do
        # 未分類の "rails" が一覧に表示されること
        get admin_unclassified_hobbies_path
        doc = Nokogiri::HTML(response.body)
        name_cells = doc.css("td[data-col='name']").map(&:text).map(&:strip)
        expect(name_cells).to include("rails")
      end

      it "分類済みタグは名前列に含まれない" do
        # 分類済みの "Ruby" は一覧エリアの名前列に出ない
        get admin_unclassified_hobbies_path
        doc = Nokogiri::HTML(response.body)
        name_cells = doc.css("td[data-col='name']").map(&:text).map(&:strip)
        expect(name_cells).not_to include("Ruby")
      end

      it "検索クエリに一致する未分類タグだけが名前列に含まれる" do
        # rails と一致しない未分類タグを追加
        create(:hobby, name: "python", parent_tag: uncategorized_parent_tag)

        # "rails" で検索
        get admin_unclassified_hobbies_path, params: { q: "rails" }
        doc = Nokogiri::HTML(response.body)
        name_cells = doc.css("td[data-col='name']").map(&:text).map(&:strip)
        expect(name_cells).to     include("rails")
        expect(name_cells).not_to include("python")
      end

      context "usage_count / user_count の集計" do
        let!(:first_owner_profile)  { create(:profile) }
        let!(:second_owner_profile) { create(:profile) }
        let!(:counted_hobby)        { create(:hobby, name: "python", parent_tag: uncategorized_parent_tag) }

        before do
          # 2ユーザーが counted_hobby を使用している状態を作る
          create(:profile_hobby, profile: first_owner_profile,  hobby: counted_hobby)
          create(:profile_hobby, profile: second_owner_profile, hobby: counted_hobby)
        end

        it "usage_count と user_count が 2 と集計されてレスポンスに含まれる" do
          get admin_unclassified_hobbies_path
          doc = Nokogiri::HTML(response.body)
          # data-hobby-id 属性の行に使用回数 "2" が含まれる
          row = doc.at_css("[data-hobby-id='#{counted_hobby.id}']")
          expect(row.text).to include("2")
        end
      end
    end

    context "一般ユーザーの場合" do
      let!(:normal_user) { create(:user) }

      before { sign_in normal_user }

      it "root_path にリダイレクトされる" do
        # 一般ユーザーはアクセス拒否される
        get admin_unclassified_hobbies_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        # 未ログインは認証ページへ
        get admin_unclassified_hobbies_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # -----------------------------------------------------------------------
  # PATCH /admin/unclassified_hobbies/:id
  # -----------------------------------------------------------------------
  describe "PATCH /admin/unclassified_hobbies/:id" do
    let!(:unclassified_hobby) { create(:hobby, name: "rails", parent_tag: uncategorized_parent_tag) }

    context "管理者の場合" do
      before { sign_in admin_user }

      it "parent_tag_id が更新されて一覧にリダイレクトされる" do
        # 1回のリクエストで DB 更新とリダイレクトを両方確認する
        patch admin_unclassified_hobby_path(unclassified_hobby),
              params: { parent_tag_id: classified_parent_tag.id }
        aggregate_failures do
          expect(unclassified_hobby.reload.parent_tag_id).to eq classified_parent_tag.id
          expect(response).to redirect_to(admin_unclassified_hobbies_path)
        end
      end

      it "分類済み hobby を対象にすると 404 を返す" do
        # Hobby.unclassified.find は未分類でない hobby で RecordNotFound を発生させる
        classified_hobby = create(:hobby, name: "Ruby", parent_tag: classified_parent_tag)
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

  # -----------------------------------------------------------------------
  # POST /admin/unclassified_hobbies/:id/merge
  # -----------------------------------------------------------------------
  describe "POST /admin/unclassified_hobbies/:id/merge" do
    let!(:source_hobby)               { create(:hobby, name: "rails", parent_tag: uncategorized_parent_tag) }
    let!(:target_hobby)               { create(:hobby, name: "Rails") }
    let!(:source_hobby_owner_profile) { create(:profile) }

    before do
      # source タグを持つプロフィールを用意する
      create(:profile_hobby, profile: source_hobby_owner_profile, hobby: source_hobby)
    end

    context "管理者の場合" do
      before { sign_in admin_user }

      it "profile_hobbies が付け替えられ source が削除されて一覧にリダイレクトされる" do
        # 1回のリクエストで付け替え・削除・リダイレクトをまとめて確認する
        post merge_admin_unclassified_hobby_path(source_hobby),
             params: { target_hobby_id: target_hobby.id }
        aggregate_failures do
          expect(
            ProfileHobby.where(hobby_id: target_hobby.id, profile_id: source_hobby_owner_profile.id)
          ).to exist
          expect(Hobby.find_by(id: source_hobby.id)).to be_nil
          expect(response).to redirect_to(admin_unclassified_hobbies_path)
        end
      end

      it "source と target が同じ場合は alert とともにリダイレクトされる" do
        # Admin::HobbyMergeService が「統合元と統合先が同じです」で失敗する
        post merge_admin_unclassified_hobby_path(source_hobby),
             params: { target_hobby_id: source_hobby.id }
        expect(response).to redirect_to(admin_unclassified_hobbies_path)
        follow_redirect!
        expect(response.body).to include("統合元と統合先が同じです")
      end
    end

    context "一般ユーザーの場合" do
      let!(:normal_user) { create(:user) }

      before { sign_in normal_user }

      it "root_path にリダイレクトされる" do
        post merge_admin_unclassified_hobby_path(source_hobby),
             params: { target_hobby_id: target_hobby.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
