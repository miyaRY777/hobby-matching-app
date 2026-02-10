FactoryBot.define do
  factory :profile do
    association :user
    bio { "テスト用の自己紹介です" }
  end
end

# profile = create(:profile)
