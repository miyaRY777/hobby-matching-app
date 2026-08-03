require "rails_helper"

RSpec.describe "Rooms::ParentTagMembers#index", type: :request do
  let(:viewer_user) { create(:user) }
  let(:viewer_profile) { create(:profile, user: viewer_user) }
  let(:room) { create(:room, room_type: :chat) }
  let(:parent_tag) { create(:parent_tag, name: "ゲーム", room_type: :chat) }
  let(:matching_hobby) { create(:hobby, name: "Among Us") }

  before do
    create(:room_membership, room:, profile: viewer_profile)
    create(:hobby_parent_tag, hobby: matching_hobby, parent_tag:)
  end

  it "未ログインならログイン画面へリダイレクトする" do
    get room_parent_tag_members_path(room_id: room.id, parent_tag_id: parent_tag.id)

    expect(response).to redirect_to(new_user_session_path)
  end

  context "ログイン済み" do
    before { sign_in viewer_user }

    it "部屋外ユーザーには403を返す" do
      outside_room = create(:room, room_type: :chat)

      get room_parent_tag_members_path(room_id: outside_room.id, parent_tag_id: parent_tag.id)

      expect(response).to have_http_status(:forbidden)
    end

    it "部屋カテゴリーと異なる親タグには404を返す" do
      study_parent_tag = create(:parent_tag, room_type: :study)

      get room_parent_tag_members_path(room_id: room.id, parent_tag_id: study_parent_tag.id)

      expect(response).to have_http_status(:not_found)
    end

    it "プロフィールID昇順で関連ユーザー全員を表示する" do
      first_profile = create_member("first_user")
      second_profile = create_member("second_user")
      third_profile = create_member("third_user")

      get room_parent_tag_members_path(room_id: room.id, parent_tag_id: parent_tag.id)

      expect(response.body).to include("関連ユーザー：3人")
      expect(response.body).to include("first_user", "second_user", "third_user")
      expect(response.body.index("first_user")).to be < response.body.index("second_user")
      expect(response.body.index("second_user")).to be < response.body.index("third_user")
      expect(response.body.scan("data-profile-id=\"#{first_profile.id}\"").size).to eq(1)
      expect(response.body.scan("data-profile-id=\"#{second_profile.id}\"").size).to eq(1)
      expect(response.body.scan("data-profile-id=\"#{third_profile.id}\"").size).to eq(1)
      expect(response.body).not_to include("member-detail-pagination", "次へ", "前へ")
    end

    it "カードには選択親タグ以外も含めた雑談カテゴリーの趣味を表示する" do
      other_chat_parent_tag = create(:parent_tag, room_type: :chat)
      study_parent_tag = create(:parent_tag, room_type: :study)
      other_chat_hobby = create(:hobby, name: "漫画")
      study_hobby = create(:hobby, name: "Rails")
      create(:hobby_parent_tag, hobby: other_chat_hobby, parent_tag: other_chat_parent_tag)
      create(:hobby_parent_tag, hobby: study_hobby, parent_tag: study_parent_tag)
      profile = create_member("tagged_user")
      create(:profile_hobby, profile:, hobby: other_chat_hobby)
      create(:profile_hobby, profile:, hobby: study_hobby)

      get room_parent_tag_members_path(room_id: room.id, parent_tag_id: parent_tag.id)

      expect(response.body).to include("Among Us", "漫画")
      expect(response.body).not_to include("Rails")
    end

    it "pageパラメータが指定されても全員を表示する" do
      create_member("first_user")
      create_member("second_user")

      get room_parent_tag_members_path(room_id: room.id, parent_tag_id: parent_tag.id, page: 99)

      expect(response.body).to include("first_user", "second_user")
      expect(response.body).not_to include("member-detail-pagination")
    end

    it "関連ユーザー数が増えてもSELECT数が増えない" do
      create_member("member_1")
      select_queries_for_parent_tag_request
      one_member_queries = select_queries_for_parent_tag_request

      4.times { |index| create_member("member_#{index + 2}") }
      select_queries_for_parent_tag_request
      five_member_queries = select_queries_for_parent_tag_request

      expect(five_member_queries.size).to eq(one_member_queries.size)
    end

    it "対象者がいなければ空状態を表示する" do
      get room_parent_tag_members_path(room_id: room.id, parent_tag_id: parent_tag.id)

      expect(response.body).to include("関連ユーザー：0人")
      expect(response.body).to include("該当するユーザーはいません")
      expect(response.body).not_to include('data-testid="member-detail-pagination"')
    end
  end

  def create_member(nickname)
    profile = create(:profile, user: create(:user, nickname:))
    create(:room_membership, room:, profile:)
    create(:profile_hobby, profile:, hobby: matching_hobby)
    profile
  end

  def select_queries_for_parent_tag_request
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if payload[:cached]
      next if %w[SCHEMA TRANSACTION].include?(payload[:name])
      next unless payload[:sql].match?(/\ASELECT/i)

      queries << payload[:sql]
    end

    get room_parent_tag_members_path(room_id: room.id, parent_tag_id: parent_tag.id)
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end
