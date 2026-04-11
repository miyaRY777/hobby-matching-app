require "rails_helper"

RSpec.describe "Profiles#show shared hobbies", type: :request do
  it "ログイン済みで他人プロフィール詳細を聞くと、共通hobbiesが表示される" do
    # ログインユーザー
    my_user = create(:user)
    my_profile = create(:profile, user: my_user)

    # 相手ユーザー
    other_user = create(:user)
    other_profile = create(:profile, user: other_user)

    # 共通Hobby
    rails = create(:hobby, name: "rails")
    create(:profile_hobby, profile: my_profile, hobby: rails)
    create(:profile_hobby, profile: other_profile, hobby: rails)

    sign_in my_user

    get profile_path(other_profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("共通の趣味")
    expect(response.body).to match(/共通の趣味.*rails/m)
  end

  it "自分のプロフィール詳細では共通の趣味セクションを表示しない" do
    my_user = create(:user)
    my_profile = create(:profile, user: my_user)

    sign_in my_user
    get profile_path(my_profile)

    expect(response).to have_http_status(:ok)
    main_content = response.body[%r{<main.*?>(.*)</main>}m, 1]
    expect(main_content).not_to include("共通の趣味")
  end

  it "共通の０件の場合、メッセージが表示される" do
    my_user = create(:user)
    my_profile = create(:profile, user: my_user)

    other_user = create(:user)
    other_profile = create(:profile, user: other_user)

    sign_in my_user
    get profile_path(other_profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("共通の趣味はまだありません")
  end

  it "ログイン済みでもプロフィール未作成なら、共通hobbyは0件扱いで表示される" do
    my_user = create(:user)
    # わざと profile を作らない

    other_user = create(:user)
    other_profile = create(:profile, user: other_user)

    sign_in my_user
    get profile_path(other_profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("共通の趣味")
    expect(response.body).to include("共通の趣味はまだありません")
  end

  it "show アクションで hobbies の余分なクエリが発行されない" do
    # ログインユーザーと相手ユーザーを用意
    current_user = create(:user)
    current_profile = create(:profile, user: current_user)
    other_user = create(:user)
    other_profile = create(:profile, user: other_user)

    # 共通の趣味を持たせる（hobbies のロードが必ず発生する状態にする）
    shared_hobby = create(:hobby, name: "rails")
    create(:profile_hobby, profile: current_profile, hobby: shared_hobby)
    create(:profile_hobby, profile: other_profile, hobby: shared_hobby)

    sign_in current_user

    # hobbies テーブルへのSQLをキャプチャ
    hobbies_queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      hobbies_queries << payload[:sql] if payload[:sql].match?(/FROM "hobbies"/)
    end

    begin
      get profile_path(other_profile)
    ensure
      # 例外発生時にも必ず購読解除する
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    expect(response).to have_http_status(:ok)
    # eager load なし: my_profile.hobbies と other_profile.hobbies で個別にSQLが発行され計3回以上
    # eager load あり: @profile と my_profile それぞれの includes で最大2回（IN句でまとめてロード）
    expect(hobbies_queries.count).to be <= 2
  end
end
