FactoryBot.define do
  factory :profile do
    association :user
    bio { "テスト用の自己紹介です" }
    # hobbies_json はバリデーション通過のために設定（実際のHobbyレコードは作成しない）
    # 各テストで必要な hobby は明示的に create(:profile_hobby, ...) で作成すること
    hobbies_json { [ { name: "FactoryBot趣味", description: "" } ].to_json }
  end
end
