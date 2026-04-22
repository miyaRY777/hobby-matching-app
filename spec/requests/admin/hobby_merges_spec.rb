require "rails_helper"

RSpec.describe "Admin::HobbyMergesController", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  let!(:programming_parent_tag) { create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study) }
  let!(:game_parent_tag) { create(:parent_tag, name: "ゲーム", slug: "game", room_type: :game) }
  let!(:source_hobby) { create(:hobby, name: "Apex") }
  let!(:target_hobby) { create(:hobby, name: "React") }
  let!(:unclassified_hobby) { create(:hobby, name: "未分類タグ") }

  before do
    create(:hobby_parent_tag, hobby: source_hobby, parent_tag: game_parent_tag)
    create(:hobby_parent_tag, hobby: target_hobby, parent_tag: programming_parent_tag)
  end

  describe "GET /admin/hobby_merges/new" do
    context "管理者の場合" do
      before { sign_in admin_user }

      it "200 OK を返す" do
        get new_admin_hobby_merge_path
        expect(response).to have_http_status(:ok)
      end

      it "親タグごとと未分類で optgroup が表示される" do
        get new_admin_hobby_merge_path

        doc = Nokogiri::HTML(response.body)
        labels = doc.css("select#source_hobby_id optgroup").map { |node| node["label"] }

        expect(labels).to include("ゲーム", "プログラミング", "未分類")
      end

      it "各 optgroup に対応するタグが表示される" do
        get new_admin_hobby_merge_path

        doc = Nokogiri::HTML(response.body)
        source_groups = doc.css("select#source_hobby_id optgroup").to_h do |group|
          [ group["label"], group.css("option").map(&:text) ]
        end

        aggregate_failures do
          expect(source_groups["ゲーム"]).to include("Apex")
          expect(source_groups["プログラミング"]).to include("React")
          expect(source_groups["未分類"]).to include("未分類タグ")
        end
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in create(:user) }

      it "root_path にリダイレクトされる" do
        get new_admin_hobby_merge_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get new_admin_hobby_merge_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /admin/hobby_merges" do
    context "管理者の場合" do
      before { sign_in admin_user }

      context "異なるタグを指定した場合" do
        it "統合元タグが削除される" do
          expect do
            post admin_hobby_merges_path,
                 params: { source_hobby_id: source_hobby.id, target_hobby_id: target_hobby.id }
          end.to change(Hobby, :count).by(-1)
        end

        it "new にリダイレクトされる" do
          post admin_hobby_merges_path,
               params: { source_hobby_id: source_hobby.id, target_hobby_id: target_hobby.id }

          expect(response).to redirect_to(new_admin_hobby_merge_path)
        end

        it "profile_hobbies が統合先に付け替えられる" do
          profile = create(:profile)
          create(:profile_hobby, profile:, hobby: source_hobby)

          post admin_hobby_merges_path,
               params: { source_hobby_id: source_hobby.id, target_hobby_id: target_hobby.id }

          expect(profile.profile_hobbies.reload.map(&:hobby_id)).to include(target_hobby.id)
        end
      end

      context "同じタグを指定した場合" do
        it "422 を返す" do
          post admin_hobby_merges_path,
               params: { source_hobby_id: source_hobby.id, target_hobby_id: source_hobby.id }

          expect(response).to have_http_status(422)
        end

        it "エラーメッセージがレスポンスに含まれる" do
          post admin_hobby_merges_path,
               params: { source_hobby_id: source_hobby.id, target_hobby_id: source_hobby.id }

          expect(response.body).to include("統合元と統合先が同じです")
        end
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in create(:user) }

      it "root_path にリダイレクトされる" do
        post admin_hobby_merges_path,
             params: { source_hobby_id: source_hobby.id, target_hobby_id: target_hobby.id }

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
