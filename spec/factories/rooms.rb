FactoryBot.define do
  factory :room do
    association :issuer_profile, factory: :profile
    label { "テスト部屋" }
  end
end
